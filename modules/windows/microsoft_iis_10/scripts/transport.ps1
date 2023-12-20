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
        "ssl-v2" {
            $server=(Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name 'Enabled').Enabled
            
            if ($LASTEXITCODE -ne 1 -and $server -eq 1 ) {
                Write-Output "1"
                exit 0;
            }

            $client=(Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'Enabled').Enabled
            
            if ($LASTEXITCODE -ne 1 -and $client -eq 1 ) {
                Write-Output "1"
                exit 0;
            }

            Write-Output "0"

        }
        "tls-1_2" {
            Write-Output ((Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled').Enabled)  
        }
        "aes-cipher-suite" {
            Write-Output ((Get-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256' -name 'Enabled').Enabled)
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
        "ssl-v2" {

            if ($data[0] -eq 0 ) {
                $enable=0
                $default=1
            } elseif ( $data[0] -eq 1) {
                $enable=1
                $default=0
            }
            
            Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name 'Enabled' -value $enable | Out-Null
            Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'Enabled' -value $enable | Out-Null
            Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name 'DisabledByDefault' -value $default | Out-Null
            Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'DisabledByDefault' -value $default | Out-Null

        }
        "tls-1_2" {

            if ($data[0] -eq 0 ) {
                $enable=0
                $default=1
            } elseif ( $data[0] -eq 1) {
                $enable=1
                $default=0
            }            
       
            Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled' -value $enable
            Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'DisabledByDefault' -value $default | Out-Null

        }
        "aes-cipher-suite" {
            Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256' -name 'Enabled' -value $data[0]
        }
        Default { echoErr "Valeur pas pris en charge: $parameter" }
    }

}



if ($action -eq "read") {
    read $parameter
} elseif ( $action -eq "change" ) {
    change $parameter $remaining
}

