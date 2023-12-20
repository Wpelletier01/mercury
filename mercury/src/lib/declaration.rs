/// Donné qui pourrait nous servire tous au long du projet

/// Emplacement des fichiers de configuration
#[cfg(target_os = "linux")]
pub const CONFIG_PATH: &str = "/etc/mercury/benchmarks";
#[cfg(target_os = "windows")]
pub const CONFIG_PATH: &str = "C:\\Program Files\\mercury\\benchmarks";
/// Emplacement des fichiers manifest
#[cfg(target_os = "linux")]
pub const MANIFEST_DIR: &str = "/opt/mercury/manifests";
#[cfg(target_os = "windows")]
pub const MANIFEST_DIR: &str = "C:\\Program Files\\mercury\\manifests";

/// Emplacement des fichiers scripts
#[cfg(target_os = "linux")]
pub const SCRIPT_DIR: &str =  "/opt/mercury/scripts";
#[cfg(target_os = "windows")]
pub const SCRIPT_DIR: &str = "C:\\Program Files\\mercury\\scripts";


#[cfg(target_os = "linux")]
pub const MERCURY_DIR: &str = "/opt/mercury";
#[cfg(target_os = "windows")]
pub const MERCURY_DIR: &str = "C:\\Program Files\\mercury";

#[cfg(target_os = "linux")]
pub const SCRIPT_EXT:&str = "sh";
#[cfg(target_os = "windows")]
pub const SCRIPT_EXT:&str = "ps1";



