
use crate::benchmark::{Benchmark, ParameterInfo};
use comfy_table::{Table, ContentArrangement};
use log::debug;


const TABLE_HEADER:[&str;4] = [ "Nom", "Description", "Valeur Config", "Valeur Trouver" ];
const TABLE_WIDTH:u16 = 140;

/// Crée un tableau sous forme de chaine de caractêre selon les données d'un Benchmark collecté qui peuvent 
/// être utilisé pour être afficher au terminal. Retourne le tableau créé.
/// 
/// # Paramètres 
/// * `benchmark`   -   Le benchmark source
/// * `diff`        -   Se préocuper seulement des donné différente entre les valeur de configuration 
///                     et les valeur collecté
/// 
pub fn print_benchmark(benchmark:&Benchmark,diff:bool) -> String {

    #[allow(unused_assignments)]
    let mut parameters: Vec<&ParameterInfo> = Vec::new();
    #[allow(unused_assignments)]
    let mut pread: String = String::new();
    #[allow(unused_assignments)]
    let mut pconf: String = String::new();

    let mut output_str: String = String::new();
    let mut section_change: usize = 0;

    output_str.push_str("\n\n\n======================================================================\n");
    output_str.push_str(&format!("BENCHMARK: {}\n",benchmark.name.to_string()));
    output_str.push_str(&format!("VERSION: {}\n", benchmark.version.to_string()));
    output_str.push_str(&format!("LIEN: {}\n",benchmark.src.to_string()));
    output_str.push_str("======================================================================\n");

    for (sid,section) in benchmark.sections.iter().enumerate() {

        let mut section_table = Table::new();

        section_table.set_header(TABLE_HEADER);
        section_table.set_content_arrangement(ContentArrangement::Dynamic);
        section_table.set_width(TABLE_WIDTH);

        parameters = benchmark.parameters_info.iter().filter(|p| p.sid == sid ).collect();

        for param in parameters.iter() {

            pconf = benchmark.get_conf_pdata_by_id(param.id)
                .expect("Ne peut pas trouver la valeur dans les paramètres collecté du fichier de config")
                .data
                .to_print();
            
            pread = match benchmark.get_read_pdata_by_id(param.id) {
                Some(pd) => pd.data.to_print(),
                None => "UNKNOWN".to_string()
            };

            if (diff && pconf != pread) || !diff {

                section_table.add_row(vec![
                    param.name.to_string(),
                    param.description.to_string(),
                    pconf,
                    pread
                ]);
            
            } else  {
                debug!("Skip paramètre: {}",param.name.to_string());
            }


        }
        
        if section_table.row_count() > 0 {
            output_str.push_str(&format!("\n\nSECTION: {section}\n"));
            output_str.push_str(&format!("{section_table}"));
            section_change+=1;
        } 

    }

    if section_change < 1 && diff {
        output_str.push_str("Aucun Paramètre différent");
    }
    
    if !benchmark.errors.is_empty() {
        output_str.push_str(&print_err(benchmark));
    }


    output_str

}

/// Crée un tableau avec les erreurs qu'un benchmark entreprose dans sont attribut erreur
pub fn print_err(benchmark:&Benchmark) -> String {

    let mut output:String = String::new();


    output.push_str("\n\n\n======================================================================\n");
    output.push_str("TABLE DES ERREURS\n");
    output.push_str("Description: Erreur survenue durant execution\n");
    output.push_str("======================================================================\n");

    let mut errors_table = Table::new();
    errors_table.set_header(vec!["PARAMETERE","DESCRIPTION"]);
    errors_table.set_content_arrangement(ContentArrangement::Dynamic);
    errors_table.set_width(TABLE_WIDTH);

    for (pname,msg) in benchmark.errors.iter() {
        errors_table.add_row(vec![pname,msg]);
    }

    output.push_str(&format!("{errors_table}"));

    output

}