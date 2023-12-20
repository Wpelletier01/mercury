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
        "unlisted-file-ext" { 
            $output=(Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/fileExtensions" -name "allowUnlisted").Value
            Write-Output ([int][bool]::Parse($output))
        }
        "not-listed-apis" { 
            $output=(Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/security/isapiCgiRestriction" -name "notListedIsapisAllowed").Value
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
        "unlisted-file-ext" { 
            $value = [bool][int]::Parse($data[0])
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/security/requestFiltering/fileExtensions" -name "allowUnlisted" -value $value
        }
        "not-listed-apis" {
            $value = [bool][int]::Parse($data[0])
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/isapiCgiRestriction" -name "notListedIsapisAllowed" -value $value
        }
        Default { echoErr "Valeur pas pris en charge: $parameter" }
    }

}



if ($action -eq "read") {
    read $parameter
} elseif ( $action -eq "change" ) {
    change $parameter $remaining
}
