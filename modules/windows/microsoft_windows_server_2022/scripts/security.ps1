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

        "limit-blank-password" {
            $status=(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse").LimitBlankPasswordUse
            Write-Output $status
        }
        "allow-print-driver" {
            $status=(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers" -Name "AddPrinterDrivers").AddPrinterDrivers
            if ("$status" -eq "0" ) {
                Write-Output "1"
            } else {
                Write-Output "0"
            }
        }
        "display-last-username" {
            $status=(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DontDisplayLastUserName").DontDisplayLastUserName
            Write-Output $status

        }

        Default { echoErr "Parametre pas pris en charge: $parameter"  }
    }

}


function change {
    param (
        [string]$parameter,
        [array]$data
    )
    
    switch ($parameter) {

        "limit-blank-password" {
            Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" -Name LimitBlankPasswordUse -Value $data[0]
        }
        "allow-print-driver" {
            $status=""

            if ($data[0] -eq "1" ) {
                $status = "0"
            } else {
                $status = "1"
            }
            Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers" -Name "AddPrinterDrivers" -Value $status
        }
        "display-last-username" {
            Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name DontDisplayLastUserName -Value $data[0]

        }

        Default { echoErr "Parametre pas pris en charge: $parameter"  }
    }

}



if ($action -eq "read") {
    read $parameter
} elseif ( $action -eq "change" ) {
    change $parameter $remaining
}

