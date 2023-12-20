#Requires -RunAsAdministrator

param (
    [Parameter(Mandatory)]
    [string]$action,
    [Parameter(Mandatory)]
    [string]$parameter,
    [Parameter(mandatory=$false, ValueFromRemainingArguments=$true)]$remaining
    
)

. $PSScriptRoot\..\..\..\lib\lib.ps1


function read {
    param (
        [string]$parameter
    )
    switch ($parameter) {
        "machine-key" {
            Write-Output (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT'  -filter "system.web/machineKey" -name "validation")
        }
        "debug-mode" {
            $output=(Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.web/compilation" -name "debug").Value
            Write-Output ([int][bool]::Parse($output))
        }
        Default { echoErr "Valeur pas pris en charge: $parameter" }
    }

}


function change {
    param (
        [string]$parameter,
        [array]$data
    )
    
    switch ($parameter) {
        "machine-key" {
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT'  -filter "system.web/machineKey" -name "validation" -value $data[0]
        }
        "debug-mode" {
            $value=([bool][int]::Parse($data[0]))
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.web/compilation" -name "debug" -value $value
        }
        Default { echoErr "Valeur pas pris en charge: $parameter" }
    }

}



if ($action -eq "read") {
    read $parameter
} elseif ( $action -eq "change" ) {
    change $parameter $remaining
}

