# 420-H34-PROJET-INTÉGRATEUR ( Mercury )

Gestionnaire de déploiement d'automatisation de Benchmark pour configurer des fichiers et valeurs de configuration
de différent services TI pour qu'il respecte les normes émis par Center for Internet Security (CIS). Tous ça en ligne de commande.

```
Lit et modifie des valeurs de configuration de différents services dans le but que ceux-ci respecte les ligne directive 
fixées par différent Benchmark produit par Center for Internet Security (CIS)

Usage: mercury [OPTIONS]

Options:
      --difference  Affiche seulement les valeurs dans le fichier de configuration et les valeurs récolter qui sont différente entre eux
      --commit      Applique les valeurs sauvegardés dans les fichiers de config
      --debug       Affiche tous les logs possibles
      --verbose     Affiche les logs de type info
  -h, --help        Print help
  -V, --version     Print version
```

## Table des matières
----

1. [Présentation](#présentation)
2. [Module](#module)
    1. [Fichier de configuration](#fichier-de-configuration)
    2. [Fichier manifest](#fichier-manifest)
    3. [Script](#script)
3. [Type de donnée](#types-de-données)
4. [Nomenclature](#nomenclature)
5. [Gestionnaire](#gestionnaire)
    1. [Parser](#parser)
    2. [Exécuteur](#exécuteur)
    3. [Terminal Printer](#terminal-printer)
6. [Installation](#installation)
    1. [Windows](#installation)
    2. [Linux](#linux)

## Présentation 
----

Mon but était de faire un programme qui est capable de s'exécuter sur plus d'un Os et que peut importe le Benchmark et son contenu, le pipeline d'exécution reste le même. Aussi, pour resté dans les demande du projet, les exécutions pour lire et modifier les paramètres des Benchmarks se font par le biais de script Powershell et Bash. Ceux-ci permet à tous d'ajouté de nouveau Benchmark facilement sans avoir à écrire du Rust. Pour que tous ceci soit possible, les benchmarks doivent pouvoir être représenté sous une forme commune. Dans ce projet, on l'ai appelle: module. Le programme en Rust est dans le dossier mercury et est référé comme le gestionnaire dans cette documentation.

## Module
----

Les modules représente un CIS Benchmark. Ils contiennent les scripts nécessaires pour l’exécution du Benchmark et les valeurs suggérés pour les différents paramètres de celui-ci sous forme de fichier de configuration.

Chacun des modules dans le dossier [module](./modules/), sont ceux que j'ai créé pour le projet.
Leur structure est important surtout lors de l'installation et elle doit tous être comme ceci:

```
exemple
├── scripts
├── manifest.json
└── exemple.toml
```

### Fichier de configuration

Le fichier de configuration sont de type toml qui est un type de fichier conçu pour faire des fichiers de configuration. Chaque fichier sont séparer en section. Une section peut représenté une sous-sections d'un Benchmark ou un rassemblement de type de paramètre semblable. Ce fichier doit se retrouver dans le dossier de configuration (voir l'emplacement dépendamment de l'os [ici](./mercury/src/lib/declaration.rs)).

Voici un exemple de fichier de configuration:

```
[pwquality] # Nom de section

minlen = 14 # declaration d'un paramètre

# minclass = 4 # paramètre 'commented out'

```

### Fichier Manifest

Le fichier manifest d'écrit au gestionnaire comment il devrait interpréter le fichier de configuration de son Benchmark. Il déclare les paramètres souhaités, de leur information ainsi que leur valeur par défaut. Celle-ci est importante car elle permet de dire au gestionnaire quel type de donné devrait-il attendre pour ce paramètre. Les valeurs par défaut devrait être ceux recommandé par le benchmark. Ce fichier est important vu qu'on souhaite que les gens puisse développer des modules sans avoir à apprendre le langage Rust.

```
{   
    # nom du benchmark
    "name": "",
    # url du benchmark
    "source": "",
    # sur quel Os devrait-il être exécuté
    "os":   "",
    # les sections à retrouvé
    "sections" : [

        {
            # nom de la section
            "name": "",
            # liste des paramètres de la section
            "parameters": [
                {   
                    # nom du paramètre
                    "name": "",
                    # url source pour le paramètre
                    "source": "",
                    # Les valeurs possible si null, aucune vérification est fait (Pas encore implémenté)
                    "expect": "",
                    # La valeur du paramètre par défaut
                    "default": "",
                    # courte description du paramètre qui sera afficher dans le rapport
                    "description": ""
                }
            ]
        }

    ]

}
```

Ce fichier doit se retrouver dans le dossier des Manifest (voir l'emplacement dépendamment de l'os [ici](./mercury/src/lib/declaration.rs)).


### Script 

Le dossier script contient tous les scripts que le module à besoin. Chaque script à deux actions possibles, 'read' qui va chercher la valeur actuelle du paramètre dans la machine et 'change' qui permet de changer une valeur d'un paramètre sur la machine.

C'est script doit satisfaire ces exigences:

* doit être nommée avec un nom de section
* le premier paramètre doit-être soit read ou change
* le deuxième paramètre doit pouvoir être un nom d'un paramètre de section 
* Si l'action est 'change', le troisième paramètre doit être la valeur dont laquelle on veut que le paramètre soit changé 
* Les entrées et sorties doivent respecter le format de données (voir [Type de donnée](#types-de-donnés))

Prenons se fichier de configuration par exemple:

```
[mdp]

foo = 4
bar = 33
```

Si nous voulons lire la valeur dans le système du paramètre foo, le gestionnaire exécutera la commande suivante:

```
mdp.sh read foo
```

Si nous voulons changer la valeur du paramètre bar pour la valeur 44, le gestionnaire exécutera la commande suivante:

```
mdp.sh change bar 44
```

Les scripts doivent se retrouver dans le dossier des Benchmarks (voir l'emplacement dépendamment de l'os [ici](./mercury/src/lib/declaration.rs)).

Un template pour un script Powershell est disponible [ici](./docs/powershell-template.ps1). Noté que la structure présenté n'est pas obligatoire si le script respecte les exigences des scripts.




## Types de données
------

Le gestionnaire traite différents types de donnée:
```
pub enum MDataType {

    Bool(bool),
    Number(i64),
    Str(String),
    File(HashMap<String,String>),
    VecString(Vec<String>)
}
```

Ces types représentent le format que les scripts et le gestionnaire utilise pour s'échanger de l'information. Ce format doit être respecter pour le bon fonctionnement du programme.

Voici comment chaque type devrait être envoyé.

Bool:

* true -> 1
* false -> 0

Number:
* rien de spéciale

Str:
* une chaîne de caractère

File:

* Une Hashtable avec les clés suivantes: 'path', 'owner' et 'permission'.

Les scripts et le gestionnaire s'échangera l'info sous forme de liste ou l’ordre de chaque donné représente sont type.

si on a une Hashtable avec les infos suivants:
```
{
    "path": "/foo/bar",
    "owner: "nobody:nobody",
    "permission": "777"
}

```

Cette donné sera envoyé de la sorte au script et vice-versa:

```
/foo/bar nobody:nobody 777
```

VecString:

Représente un vecteur de chaîne de caractère. La seule contrainte est que chaque element doit être entouré de simple guillemet. Les scripts doivent pouvoir accueillir se type de donné sous forme d'argument de ligne de commande. Par exemple, le paramètre foo prend un argument de type VecString avec ces valeurs dans un fichier de config:

```
foo = [ "this", "is", "a", "test" ]
```

Pour une exécution de type 'change' sur se paramètre, le gestionnaire exécutera son script respectif de la sorte:

```
example.sh change foo 'this' 'is' 'a' 'test'
```

Les simples guillemets sont important car il prévient les éléments d'une liste contenant des espaces d'être considéré comme plusieurs éléments.



## Nomenclature
----

Les noms des fichiers de configuration et les nom des dossiers des scripts doivent être formé du nom du Benchmark entré dans le manifest. Le gestionnaire les interprétera en modifiant leur contenu avec les contraintes suivantes:
* les espaces doivent être remplacé par '_'
* les points doivent être remplacé par '__' 

Cette nomenclature est important pour le bon fonctionnement du programme et toutes responsabilités tombent sur le développeur d'un module.

## Gestionnaire 
-----

L'un des points intéressant d'utilisé Rust étais la possibilité de créer facilement un exécutable qui marche pour les machine Linux et Windows. Ceci est possible grace au concept de la [compilation conditionnelle](https://en.wikipedia.org/wiki/Conditional_compilation). En résumé, ça permet d'inclure ou d'exclure des portions de code source pendant la phase de compilation, en fonction de certaines conditions prédéfinies. Dans notre cas, la conditions est le type d'Os. Par exemple:
```
#[cfg(target_os = "linux")]
let foo = "sh";
#[cfg(target_os = "windows")]
let foo = "ps1";
```

Si le source code est compiler sur un os de windows, la première valeur foo sera omit et vice-versa. 

### Parser

C'est ici que les fichiers manifests et de configurations sont traduits et valider avant d'être entreposer pour l'exécution. L'un des point attrayant que Rust nous offre vient dans l'une de ces librairies nommé Serde. Elle permet la sérialisation et déserialisation des structures de données Rust. Elle nous permet facilement de lire le contenu de nos fichier manifest et de s’assurer de leur validité pour ensuite être entreposer pour être utiliser au besoin. Si vous prenez en compte le format d'un [fichier manifest](#fichier-manifestjson), celui sera traduit dans la structure suivante:

```
#[derive(Debug,Deserialize,Clone)]
pub struct MParameter {

    pub name:           String,
    pub source:         String,
    pub expect:         Option<MDataType>,
    pub default:        MDataType,
    pub description:    String

}
```

La même logique aurais pu s’être appliquer pour les fichiers de configuration, mais en faisant ainsi, on aurai rendu le développent de module plus complexe et moins modulaire. C'est plus facile de créer un fichier json que d'écrire en Rust pour la plus part du monde.

### Exécuteur

Cette partie est relativement simple. Le gestionnaire crée un nouveau processus powershell pour windows, bash pour Linux pour chaque paramètre. C'est aussi un autre endroit où l’amélioration du programme serais possible. Il est déjà assez rapide d'exécution mais je n'ai pas beaucoup d'argument. Si un jour, il commence avoir un grand nombre d'argument, il serait intéressant d'exécuter plusieurs processus à la fois. Vu la simplicité de cette partie il serait très facile à implémenter.


### Terminal Printer

Cette partie génère le rapport des trouvailles du gestionnaire. Ceux-ci sont très rudimentaire et amélioré les affichages serait une bonne idée. Il est conseillé d'exécuter le programme dans un terminal ouvert au maximum pour des meilleurs résultat.


## Installation 
-----

Pour pouvoir utiliser ce projet vous devez cloner se dépôt sur votre machine et utiliser l'un des scripts d'installation.

Noter que pour s'assurer du fonctionnement des modules de Windows, il ont des dépendances et de valeur à initialiser dans le register de Windows avant de pouvoir s'exécuter. Il seront fait dans le script d'installation pour l'instant, mais il serait intéressant de rajouter une fonctionnalité dans les modules pour leur d'exécuter du code d'initialisation.

Aussi, le gestionnaire n'a aucune façon de savoir sont environment d'exécution est valide. Naturellement, si vous essayez par exemple d'exécuter un Benchmark Postgresql conçu pour une machine Ubuntu, mais qu'il n'est pas installé, ça ne marchera pas.
 
Après l'installation, vous devriez être en mesure de lancer la commande 'mercury' de partout sur les deux Os. Vous devez l'exécuter avec les droits d'administrateur dans tous les cas. 

### Windows

Tester seulement sur Windows serveur 2022. Pour le modules Microsoft IIS, vous devez avoir IIS d'installé et configuré.

Exécuté le script powershell [install.ps1](./install/install.ps1) dans le dossier install du dépôt avec les droits administrateurs.

```
./install.ps1
```

### Linux 

Pour le module Postgresql 14, il doit être installé sur un serveur Ubuntu 22.04.
Pour le module Ubuntu 22.04, libpam-pwquality doit être installé.

Exécuté le script bash [install.sh](./install/install.sh) dans le dossier install du dépôt. 

```
sudo ./install.sh
```


