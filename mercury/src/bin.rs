
use libmercury::{*, benchmark::{ParameterData, Benchmark}, executer::{execute, output_to_dtype, ExecutionError}};
use log::{debug,error};
use clap::Parser;
use anyhow::{Context,Result};
use std::process;

use libmercury::declaration::*;




#[derive(Parser)]
#[command(author, version = "0.1.1", about, long_about = None)]
/// Lit et modifie des valeurs de configuration de différents services
/// dans le but que ceux-ci respecte les ligne directive fixées par différent 
/// Benchmark produit par Center for Internet Security (CIS)
struct Mercury {
    /// Affiche seulement les valeurs dans le fichier de configuration et
    /// les valeurs récolter qui sont différente entre eux
    #[arg(long)]
    difference: bool,
    /// Applique les valeurs sauvegardés dans les fichiers de config 
    #[arg(long)]
    commit: bool, 
    /// Affiche tous les logs possibles
    #[arg(long)]
    debug: bool,
    /// Affiche les logs de type info
    #[arg(long)]
    verbose: bool 
}


fn main() -> Result<()> {
    
    // Traite les arguments passée en ligne de commande
    let cfg = Mercury::parse();

    let mut env_log_builder = env_logger::builder();

    if cfg.verbose {
        env_log_builder.filter_level(log::LevelFilter::Info);
    }

    if cfg.debug {
        env_log_builder.filter_level(log::LevelFilter::Debug);
    }

    
    env_log_builder.init();

    let mut benchmarks: Vec<Benchmark> = Vec::new();
     
    let manifests = parser::parse_manifests(MANIFEST_DIR)
        .with_context(|| "L'analyse des fichiers manifests a echoué")?;

    let configs = parser::parse_config(CONFIG_PATH)
        .with_context(|| "L'analyse des fichiers de config a echoué")?;
    

    for (cname,config) in configs.iter() {
        for manifest in manifests.iter() {

            if &manifest.name.to_lowercase().replace(' ', "_").replace('.', "__") == cname {

                let benchmark = parser::create_benchmark(manifest, config)
                    .with_context(|| format!("Incapable d'initialiser le benchmark '{cname}'"))?;

                benchmarks.push(benchmark);
            }

        }
    
    }

    // On effectue quand même une lecture si nous exécutons avec le paramêtre '--commit' car nous 
    // voulons seulement changer que les valeurs différentes que celle des valeurs du fichier de config
    for benchmark in benchmarks.iter_mut() {
        read(benchmark);
        debug!("{} valeur(s) lue",benchmark.read_parameter.len());
    }



    // on lit
    if (cfg.difference && !cfg.commit) || (!cfg.difference && !cfg.commit) {
        
        let mut output:String = String::new();
       
        for benchmark in benchmarks.iter() {
            output.push_str(&format!("{}\n",printer::print_benchmark(benchmark,cfg.difference)));
        }

        println!("{output}");
    
    // on change
    } else if !cfg.difference && cfg.commit {

        for benchmark in benchmarks.iter_mut() {
            change(benchmark);

            if !benchmark.errors.is_empty() {
                println!("{}",printer::print_err(&benchmark));
            }

        }
        

    // on ne veut pas les deux actions dans la meme execution
    } else {
        error!("Vous ne pouvez que spécifier une action à la fois");
        process::exit(1);
    }

    
    Ok(())

}


/// Effectue la collecte de donnée de tous les parametres du benchmark
pub fn read(benchmark:&mut Benchmark) {
    
    // Convertis le nom d'un benchmark selon notre nommenclature pour les noms de dossier
    let bname = benchmark.name.replace(' ', "_").replace('.', "__").to_lowercase();

    for parameter in benchmark.parameters_info.iter() {

        debug!("{pname} Exécute cmd: read",pname = parameter.name.to_string());

        match execute(SCRIPT_DIR,"read",&parameter.name,&bname,&benchmark.sections[parameter.sid],None) {

            Ok(output) => {

                match output_to_dtype(
                    &output,
                    &benchmark.get_conf_pdata_by_id(parameter.id).expect("Paramètre n'a aucune donnée entreposé").data
                ) {

                    Ok(d) => {
                        benchmark.read_parameter.push(ParameterData::new(parameter.id, d));
                    },
                    Err(e) => {
                        benchmark.errors.push((parameter.name.to_string(),e.to_string()));
                    }

                }

            },

            Err(e) => {

                match e {
                    ExecutionError::IoErr(e) => { 
                        eprintln!("{e}");
                    },
                    _ => { 
                        benchmark.errors.push((parameter.name.to_string(),e.to_string()));
                    }

                }

            }

        }

    }

}

/// Effectue les changements pour tous les valeurs dans le fichier de config du benchmark qui ont 
/// été lu avec des valeurs diférentes
pub fn change(benchmark:&mut Benchmark) {
    
    // Convertis le nom d'un benchmark selon notre nommenclature pour les noms de dossier
    let bname = benchmark.name.replace(' ', "_").replace('.', "__").to_lowercase();

    for parameter in benchmark.parameters_info.iter() {

        
        let pcdata = benchmark
            .conf_parameter
            .iter()
            .filter(|p| p.id == parameter.id )
            .cloned()
            .collect::<Vec<ParameterData>>()
            .first()
            .expect("Aucun paramètre est lié à une valeur de config")
            .clone();
        
        match benchmark
            .read_parameter
            .iter()
            .filter(|p| p.id == parameter.id)
            .cloned()
            .collect::<Vec<ParameterData>>()
            .first() {

            Some(d) => {
                debug!("Valeur en Config: {}",pcdata.data.to_output());
                debug!("Valeur lu: {}", d.data.to_output());

                if &d.data != &pcdata.data {
                    debug!("{pname} Exécute commande: change",pname = parameter.name.to_string());

                    match execute(SCRIPT_DIR,"change",&parameter.name,&bname,&benchmark.sections[parameter.sid],Some(&pcdata.data.to_output())) {
                        Ok(s) => {
                            debug!("Exécution '{}' retourne: {}",&parameter.name,s);
                        },
                        Err(e) => {
                            benchmark.errors.push((parameter.name.to_string(),e.to_string()));
                        }
                        
                    }

                } else {
                    debug!("Skip {}: valeur identique",parameter.name.to_string());
                }

            },
            None => debug!("Skip {}: Aucune valeur a été lu",parameter.name.to_string())

        }


    }


}

