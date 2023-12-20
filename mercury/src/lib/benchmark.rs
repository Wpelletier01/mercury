use crate::parser::manifest::MDataType;



/// Entrepose les valeurs importante d'un paramètre de section
#[derive(Debug,Clone)]
pub struct ParameterInfo {
    pub id:             usize,
    // section id, l'index dans le vecteur sections dans la structure Benchmark
    pub sid:            usize, 
    pub source:         String,
    pub name:           String,
    pub description:    String,
}

impl ParameterInfo {
    
    pub fn new(id:usize,sid:usize,source:String,name:String,description:String) -> Self {
        Self { id,sid,source: source, name, description }
    }

}

/// Entrepose un MDatatype avec un id pointant vers une structure ParameterInfo
#[derive(Debug,Clone)]
pub struct ParameterData {
    pub id:             usize,
    pub data:           MDataType
} 

impl ParameterData {
    pub fn new(id:usize,data:MDataType) -> Self { Self { id, data } }
}


/// Entrepose les valeurs importante d'un benchmark
#[derive(Debug)]
pub struct Benchmark {
    pub src:                String,
    pub version:            String,
    pub name:               String,
    pub sections:           Vec<String>,
    pub parameters_info:    Vec<ParameterInfo>,
    pub conf_parameter:     Vec<ParameterData>,
    pub read_parameter:     Vec<ParameterData>,
    pub errors:             Vec<(String,String)>,

}

impl Benchmark {
    
    pub fn new(name:&str,version:&str,src:&str,sections:Vec<String>,parameters_info:Vec<ParameterInfo>,conf_parameter:Vec<ParameterData>) -> Self {
        Self { 
            src:                src.to_string(), 
            version:            version.to_string(), 
            name:               name.to_string(), 
            sections, 
            parameters_info, 
            conf_parameter, 
            read_parameter:     Vec::new(),
            errors:             Vec::new(),
        }
    }

    /// Retourne la valeur dans le vecteur conf_parameter qui a l'id passé 
    pub fn get_conf_pdata_by_id(&self,id:usize) -> Option<&ParameterData> {

        for pdata in self.conf_parameter.iter() {

            if id == pdata.id {
                return Some(pdata);
            }

        }

        None
    }

    /// Retourne la valeur dans le vecteur read_parameter qui a l'id passé 
    pub fn get_read_pdata_by_id(&self,id:usize) -> Option<&ParameterData> {

        for pdata in self.read_parameter.iter() {

            if id == pdata.id {
                return Some(pdata);
            }

        }

        None
    }


}

