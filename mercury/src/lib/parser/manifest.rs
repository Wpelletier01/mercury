
use std::collections::HashMap;

use serde::Deserialize;


#[derive(Debug,Deserialize)]
pub struct Manifest {

    pub name:       String,
    pub version:    String,
    pub source:     String,
    pub os:         String,
    pub sections:   Vec<MSection>

}

impl Manifest {


    pub fn get_parameters(&self,s:&str,p:&str) -> Option<&MParameter> {

        for section in self.sections.iter() {

            if section.name == s {
                
                for parameter in section.parameters.iter() {
                    if parameter.name == p {
                        return Some(parameter);
                    }
                }
        
            }

        }

        None

    }



    pub fn have_parameter_in_section(&self,s:&str,p:&str) -> bool {

        for section in self.sections.iter() {

            if section.name == s {
               
                for parameter in section.parameters.iter() {
                    if parameter.name == p {
                        return true;
                    }
                }
                
            }

        }

        false

    } 

    pub fn have_section(&self,name:&str) -> bool {

        for section in self.sections.iter() {
            if section.name == name {
                return true;
            }
        }

        false
    }

}



#[derive(Debug,Deserialize)]
pub struct MSection {
    pub name: String,
    pub free_parameters_type: Option<MDtypeName>,
    pub parameters: Vec<MParameter>
}

#[derive(Debug,Deserialize,Clone)]
pub struct MParameter {

    pub name:           String,
    pub source:         String,
    pub expect:         Option<MDataType>,
    pub default:        MDataType,
    pub description:    String

}



#[derive(Debug,Deserialize,Clone)]
pub enum MDtypeName {
    #[serde(rename = "bool")]
    Bool,
    #[serde(rename = "string")]
    String,
    #[serde(rename = "number")]
    Number,
    #[serde(rename = "vec-string")]
    VecString,
    #[serde(rename = "file")]
    File

}


#[derive(Debug,Deserialize,Clone,PartialEq,Eq)]
#[serde(untagged)]
pub enum MDataType {

    Bool(bool),
    Number(i64),
    Str(String),
    File(HashMap<String,String>),
    VecString(Vec<String>),

}

impl From<toml::Value> for MDataType {
    fn from(value: toml::Value) -> Self {
        match value {
            toml::Value::Boolean(b) =>     Self::Bool(b),
            toml::Value::Integer(i) =>      Self::Number(i),
            toml::Value::String(s) =>    Self::Str(s),
            toml::Value::Array(arr) => 
                Self::VecString(arr.iter().map(|d| d.to_string()).collect::<Vec<String>>()),
            toml::Value::Table(table) => {
                let mut hmap = HashMap::new();

                for (key,val) in table.iter() {
                    hmap.insert(key.to_string(), val.to_string());
                }
                Self::File(hmap)
            },
            _ => { panic!("Type de valeur toml pas pris en charge"); }
        }
    }
}

impl MDataType {
    
    pub fn is_bool(&self) -> bool {

        if let MDataType::Bool(_) = self {
            return true;
        }

        false
    }

    pub fn is_string(&self) -> bool {
        if let MDataType::Str(_) = self {
            return true;
        }

        false 
    }

    pub fn is_number(&self) -> bool {
        if let MDataType::Number(_) = self {
            return true;
        }

        false 
    }

    pub fn is_vec_str(&self) -> bool {
        if let MDataType::VecString(_) = self {
            return true;
        }

        false 
    }

    pub fn is_file(&self) -> bool {
        if let MDataType::File(_) = self {
            return true;
        }
        false
    }

    pub fn to_output(&self) -> String {
        match self {
            Self::Bool(b) => {
                if *b {
                    return "1".to_string();
                }

                "0".to_string()
            },
            Self::File(f) => {
                return format!(
                    "{path} {owner} {permission}",
                    path = f.get("path").expect("manque valeur path dans file"),
                    owner = f.get("owner").expect("manque valeur owner dans file"),
                    permission = f.get("permission").expect("manque valeur permission dans file")
                );
            },
            Self::Number(i) => i.to_string(),
            Self::Str(s) => s.to_string(),
            Self::VecString(vs) => { 

                let mut v = vs.clone();

                for s in v.iter_mut() {
                    *s = format!("'{s}'");

                }

                return v.join(" ")

            }
        }
    }

    pub fn to_print(&self) -> String {

        match self {
            Self::Bool(b) => {
                if *b {
                    return "true".to_string();
                } 

                return "false".to_string()
            },
            Self::File(f) => {

                let mut print_out:String = String::new();

                print_out.push_str(
                    &format!(
                        "path: {} ",
                        f.get("path").expect("Incapable d'aller chercher valeur path pour fichier").replace('"', "")
                    )
                );

                print_out.push_str(
                    &format!(
                        "owner: {} ",
                        f.get("owner").expect("Incapable d'aller chercher valeur owner pour fichier").replace('"', "")
                    )
                );               
        
                print_out.push_str(
                    &format!(
                        "permission: {} ",
                        f.get("permission").expect("Incapable d'aller chercher valeur permission pour fichier").replace('"', "")
                    )
                );   

                return print_out;
            },
            Self::Number(n) => n.to_string(),
            Self::Str(s) => {
                if s.is_empty() {
                    return  "EMPTY".to_string();
                }
                return s.to_string()
            
            },
            Self::VecString(vs) => {
                
                if vs.is_empty() {
                    return "EMPTY".to_string()
                }
                return vs.iter().map(|s| s.replace("'", "").replace("\"", "")).collect::<Vec<String>>().join("\n");
            }

        }

    }

}

impl ToString for MDataType {
    
    fn to_string(&self) -> String {
        match *self {

            Self::Bool(_) => "bool",
            Self::File(_) => "file",
            Self::Number(_) => "number",
            Self::Str(_) => "string",
            Self::VecString(_) => "vec-string"
            
        }.to_string()
    }

}
