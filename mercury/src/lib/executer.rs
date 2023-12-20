
use log::debug;

use crate::parser::manifest::MDataType;

use std::collections::HashMap;
use std::string::FromUtf8Error;

use std::str;
use std::num::ParseIntError;


#[derive(Debug,thiserror::Error)]
pub enum ExecutionError {

    #[error("Input Error: {0}")]
    InputError(String),

    #[error("{0}")]
    ExecError(String),

    #[error("Retour de script invalide: attend type: {0} mais recu {1}")]
    ReadReturn(String,String),

    #[error(transparent)]
    IoErr(#[from] std::io::Error),

    #[error(transparent)]
    ParseIntErr(#[from] ParseIntError),

    #[error(transparent)]
    FUtf8Err(#[from] FromUtf8Error)

}


/// Crée un processus qui exécute un script selon l'OS sur laquelle se programme est exécuté.
/// Retourne ce qui a été écrit dans la sortie stdout. Retourne erreur si processus ne retourne pas
/// un code 0.
/// 
/// # Arguments
/// 
/// * `script_dir`  - le nom du dossier contenant les scripts
/// * `action`      - soit 'change' ou 'read'
/// * `param`       - le nom du parametre
/// * `bname`       - le nom du Benchmark
/// * `section`     - le nom de la section que le parametre est entreprosé
/// * `data`        - (optionnel) la ou les valeur à être envoyé au script pour les executions de type `change`
/// 
pub fn execute(script_dir:&str,action:&str,param:&str,bname:&str,section:&str,data:Option<&str>) -> Result<String,ExecutionError> {

    // On passe rien si vide
    let d = data.unwrap_or("");
    

    #[cfg(target_os = "linux")]
    let cmd = format!("{script_dir}/{bname}/{section}.sh {action} {param} {d}");

    #[cfg(target_os = "linux")]
    debug!("commande exécuté: {cmd}");
    #[cfg(target_os = "windows")]
    debug!("commande exécuté: {script_dir}\\{bname}\\{section}.ps1 {action} {param} {d}");

    #[cfg(target_os = "linux")]
    let exec = std::process::Command::new("bash")
        .arg("-c")
        .arg(format!("{script_dir}/{bname}/{section}.sh {action} {param} {d}"))
        .output()?;


    #[cfg(target_os = "windows")] 
    let exec = std::process::Command::new("powershell")
        .arg("-File")
        .arg(format!("{script_dir}\\{bname}\\{section}.ps1"))
        .arg(action)
        .arg(param)
        .arg(d)
        .output()?;


    if exec.status.success() {
        return Ok(String::from_utf8(exec.stdout)?.trim().to_string());
    }
    
    Err(ExecutionError::ExecError(String::from_utf8(exec.stdout)?))

} 



/// Crée une donné type Mercury selon un retoure de commande. 
/// Retourne une erreur si le retour de commande ne peut se tranformer en ce qui est souhaité.
/// 
/// # Paramètres
/// 
/// * `output`          - le retour de commande à être transformé.
/// * `dtype_desired`   - le type de donné qu'on souhaite transformé le retour de commande vers.
/// 
pub fn output_to_dtype(output:&str,dtype_desired:&MDataType) -> Result<MDataType,ExecutionError> {

    match dtype_desired {

        MDataType::Bool(_) => {

            if output == "1" {
                return Ok(MDataType::Bool(true));
            } else if output == "0" {
                return Ok(MDataType::Bool(false));
            } 

            return Err(ExecutionError::ReadReturn("bool".to_string(), output.to_string()));
        },

        MDataType::File(_) => {
            
            let soutput = output.split(' ').collect::<Vec<&str>>();
            
            if soutput.len() != 3 {
                return Err(ExecutionError::ReadReturn("file".to_string(), output.to_string()));
            }

            let mut file:HashMap<String, String> = HashMap::new();

            file.insert("path".to_string(), soutput[0].to_string());
            file.insert("owner".to_string(), soutput[1].to_string());
            file.insert("permission".to_string(),soutput[2].to_string());

            return Ok(MDataType::File(file));

        },

        MDataType::Number(_) => { return Ok(MDataType::Number(output.parse::<i64>()?));},
        MDataType::Str(_) => { return Ok(MDataType::Str(output.to_string())) },
        MDataType::VecString(_) => {
            // les elements du vecteur doivent etre reçu dans en 'quote'
            let mut vstring = output.split("'").into_iter().filter(|s| s != &" " && s != &"'" && !s.is_empty() ).map(|s| s.to_string()).collect::<Vec<String>>();
            // Trié pour etre plus facilement comparer avec un autre vecteur de string
            vstring.sort();
            
            return Ok(MDataType::VecString(vstring));
        }

    }
    
}