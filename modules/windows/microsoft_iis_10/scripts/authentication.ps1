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
        "require-ssl" {
            $output=(Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site'  -filter 'system.web/authentication/forms' -name 'requireSSL' ).Value                   
            Write-Output ([int][bool]::Parse($output))
        }
        "forms-authentication" {
            Write-Output (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site'  -filter 'system.web/authentication/forms' -Recurse -name 'cookieless')
        }
        "password-format" { 
            Write-Output (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter 'system.web/authentication/forms/credentials' -name 'passwordFormat')
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
        "require-ssl" {
            $value = ([bool][int]::Parse($data[0]))
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site'  -filter 'system.web/authentication/forms' -name 'requireSSL' -value $value | Out-Null
        }
        "forms-authentication" {
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site'  -filter 'system.web/authentication/forms' -name 'cookieless' -value $data[0]
        }
        "password-format" {
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter 'system.web/authentication/forms/credentials' -name 'passwordFormat' -value $data[0]
        }
        Default { echoErr "Valeur pas pris en charge: $parameter" }
    }

}



if ($action -eq "read") {
    read $parameter
} elseif ( $action -eq "change" ) {
    change $parameter $remaining
}

