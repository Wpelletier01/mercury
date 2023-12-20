use std::fs; 
use std::path::PathBuf;

use std::collections::VecDeque;
use log::info;

use self::manifest::{Manifest, MParameter, MDataType};
use crate::benchmark::{ParameterData,ParameterInfo, Benchmark};

pub mod manifest;

const FILE_DICT_KEY:[&str;3] = [ "path", "permission", "owner" ];

#[derive(Debug,thiserror::Error)]
pub enum ParsingError {
    
    #[error("'{path}': {src}")]
    IOError{
        src: String,
        path:   String
    },

    #[error(transparent)]
    JsonParse(#[from] serde_json::Error),

    #[error(transparent)]
    TomlParse(#[from] toml::de::Error),

    #[error("Invalide nom de fichier : '{0}'. Assurrez-vous que le fichier finit par .json")]
    DbFileName(PathBuf),

    #[error("Manque section obligatoire dans config: section: {0}")]
    MissingConfigSection(String),

    #[error("Manque parametre obligatoire dans section '{0}': parametre: {1}")]
    MissingConfigParmeter(String,String),

    #[error("Section doivent etre de type table")]
    BadSectionType,

    #[error("Invalide type de parametre pour {0}: expect: {1}")]
    BadParameterType(String,String),

    #[error("Version invalide: benchmark: '{0}' config: '{1}'")]
    VersionProblem(toml::Value,String),

    #[error("Valeur toml pas pris en charge")]
    UnknownTomlValue,

    #[error("parametre fichier mal former: manque valeur {0}")]
    MissingFileParameter(String)
}


/// Convertis les donnés d'un ou plusieurs fichier(s) manifest dans des instances Manifest.
/// Il transpose tous les fichier dans le dossier passé qui sont conforme au critere des
/// fichiers manifeste  
pub fn parse_manifests(manifest_dir:&str) -> Result<Vec<Manifest>,ParsingError> {

    let mut pmanifests:Vec<manifest::Manifest> = Vec::new();

    let directory = fs::read_dir(manifest_dir)
        .map_err(|e| ParsingError::IOError { src: e.to_string(), path: manifest_dir.to_string() })?;

    // toute autre entrer qui ne sont pas des fichiers ou qui n'ont pas l'extension 'json'
    // seront ignorer
    for entry in directory {

        let entry = entry
            .map_err(|e| ParsingError::IOError { src: e.to_string(), path: manifest_dir.to_string()})?;

        let path = entry.path();

        if path.is_file() {

            if let Some(ext) = path.extension() {

                if ext == "json" {
                    pmanifests.push(parse_manifest(&path)?);
                    info!("Trouvé manifest: {:#?}",entry.file_name());
                }

            } else {
                return Err(ParsingError::DbFileName(path))
            }
        }
    }

    info!("Fichier Manifest trouvé: {}",pmanifests.len());

    Ok(pmanifests)


}

/// Transpose un fichier manifest vers une instance Manifest
fn parse_manifest(path:&PathBuf) -> Result<Manifest,ParsingError> {

    let content = fs::read_to_string(path)
        .map_err(|e| ParsingError::IOError { src: e.to_string(), path: path.to_str().unwrap().to_string() })?;

    let pmanifest:manifest::Manifest = serde_json::from_str(&content)?;

    Ok(pmanifest)
}

/// Transpose les fichiers tomls dans un dossier versd des instances de table toml
/// et retourne un vecteur avec ceux trouvé et leur nom.
pub fn parse_config(conf_dir:&str) -> Result<Vec<(String,toml::Table)>,ParsingError> {

    let directory = fs::read_dir(&conf_dir)
        .map_err(|e| ParsingError::IOError { src: e.to_string(), path: conf_dir.to_string() })?;

    let mut config_table:Vec<(String,toml::Table)> = Vec::new();

    // toute autre entrer qui ne sont pas des fichiers ou qui n'ont pas l'extension 'toml'
    // seront ignorer
    for entry in directory {

        let entry = entry
            .map_err(|e| ParsingError::IOError { src: e.to_string(), path: conf_dir.to_string() })?;

        let path = entry.path();

        if path.is_file() {

            if let Some(ext) = path.extension() {

                if ext == "toml" {
                    
                    let content = fs::read_to_string(&path)
                        .map_err(|e| ParsingError::IOError { src: e.to_string(), path: path.to_str().unwrap().to_string()})?;
                    config_table.push(
                        (
                            path.file_name().unwrap().to_string_lossy().into_owned().replace(".toml",""),
                            toml::from_str::<toml::Table>(&content)?
                        )
                    );

                    info!("Fichier Benchmark trouvé: {:#?}",entry.file_name());

                }

            }

        }
        
    }

    info!("Fichier Benchmark trouvé: {}",config_table.len());

    Ok(config_table)

}


/// Va chercher une valeur d'un parametre dans une section precise d'un ficher de config
/// Retourne erreur si n'a pas trouvé
fn get_parameter_value(config:&toml::Table,section:&str,parameter:&str) -> Result<toml::Value,ParsingError> {

    if let Some(section) = config.get(section) {

        match section {
            toml::Value::Table(stable) => {

                if let Some(param) = stable.get(parameter) {
                    return Ok(param.to_owned());
                } else {
                    return Err(ParsingError::MissingConfigParmeter(section.to_string(),parameter.to_string()));
                }

            }
            _ => { return Err(ParsingError::BadSectionType); }
        }
        

    } else {
        return Err(ParsingError::MissingConfigSection(section.to_string()));
    }


}

/// Crée une instance Benchmark à l'aide des informations d'un manifest et le contenue d'un fichier 
/// de configuration. Retourne erreur si les donné dans le fichier de config ne respecte pas les 
/// déclaration souhaiter d'un manifeste
pub fn create_benchmark(manifest:&Manifest,config:&toml::Table) -> Result<Benchmark,ParsingError> {

    // s'assure que la version est identique
    let version = get_parameter_value(config, "general", "version")?;
    
    if version.to_string().replace('\"', "") != manifest.version {
        return Err(ParsingError::VersionProblem(version, manifest.version.to_string()));
    }   

    let mut parameters_info:Vec<ParameterInfo> = Vec::new();
    let mut parmeters_data:Vec<ParameterData>  = Vec::new();

    let mut sections:Vec<String> = Vec::new();

    let mut pid_ctn = 0;

    for (sid,msection) in manifest.sections.iter().enumerate() {
        
        if let Some(csection) = config.get(&msection.name) {

            sections.push(msection.name.to_string());

            // la section "est bien une section" et non un parametre itinérant
            if let toml::Value::Table(table) = csection {

                let mut mparameters:VecDeque<MParameter> = msection.parameters.clone().into();
                
                #[allow(unused_assignments)]
                let mut found = false;
                
                while !mparameters.is_empty() {

                    found = false;

                    for (key,val) in table.iter() {
                        
                        if key == &mparameters[0].name {

                            found = true;
                            
                            if !is_the_same(&mparameters[0].default, val) {
                                return Err(ParsingError::BadParameterType(mparameters[0].name.to_string(), mparameters[0].default.to_string()));
                            }

                            parameters_info.push(
                                ParameterInfo::new(
                                    pid_ctn, 
                                    sid, 
                                    mparameters[0].source.to_string(),
                                    mparameters[0].name.to_string(), 
                                    mparameters[0].description.to_string()
                                )
                            );

                            parmeters_data.push(ParameterData::new(pid_ctn, MDataType::from(val.clone())));

                            mparameters.pop_front();

                            break;

                        }
    
                    }

                    // n'a pas été déclaré alors valeur par défaut
                    if !found {
                        parameters_info.push(
                            ParameterInfo::new(
                                pid_ctn,
                                sid, 
                                mparameters[0].source.to_string(), 
                                mparameters[0].name.to_string(), 
                                mparameters[0].description.to_string()
                            )
                        );

                        parmeters_data.push(ParameterData::new(pid_ctn, mparameters[0].default.clone()));
                        mparameters.pop_front();
                    }

                    pid_ctn+=1;

                }
 
            }
        
        // on prend les valeur par défaut
        } else {

            sections.push(msection.name.to_string());


            for param in msection.parameters.iter() {

                parameters_info.push(
                    ParameterInfo::new(
                        pid_ctn, 
                        sid, 
                        param.source.to_string(), 
                        param.name.to_string(), 
                        param.description.to_string()
                    )
                );

                parmeters_data.push(ParameterData::new(pid_ctn, param.default.clone() ));

                pid_ctn+=1;

            }

        }
        

    }

    Ok(
        Benchmark::new(
            &manifest.name, 
            &version.to_string(), 
            &manifest.source, 
            sections, 
            parameters_info, 
            parmeters_data
        )
    )
}




/// Regarde si le type de donné dans le fichier de config est le meme que celle
/// attendu dans le manifest 
fn is_the_same(dtype:&MDataType,config_value:&toml::Value) -> bool {


    match config_value {

        toml::Value::Array(arr) => {
            
            if dtype.is_vec_str() {
                
                for value in arr.iter() {
                    // juste vecteur de string qui sont pris en charge pour l'instant
                    match value {
                        
                        toml::Value::String(_) => {},
                        _ => { return false; }
                    }
                    
                }

                return true;

            } 

            return false;


        }
        toml::Value::Boolean(_) => {
            return dtype.is_bool();
        }
        toml::Value::Integer(_) => {
            return dtype.is_number();
        },
        toml::Value::String(_) => {
            return dtype.is_string();
        },
        // file
        toml::Value::Table(table) => {
        
            for key in FILE_DICT_KEY.iter() {
                
                if !table.contains_key(&key.to_string()) {
                    return false;
                }
            }
            return true;
           
        }
        _ => { return false; }
    }


}

