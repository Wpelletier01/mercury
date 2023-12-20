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

    switch($parameter) {

        "spools-print-jobs" {
            $status=(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Spooler" -Name "Start").Start 
            
            if ( $status -eq 4 ) {
                Write-Output "0"
            } else {
                Write-Output "1"
            }
        }
     
        Default { echoErr "Parametre pas pris en charge: $parameter"  }
    }    


}


function change {
    param (
        [string]$parameter,
        [array]$data
    )
    
    switch($parameter) {

        "spools-print-jobs" { 
            
            if ( $data[0] -eq 1 ) {
                $status=2   
            } elseif ( $data[0] -eq 0) {
                $status=4
            } else {
                echoErr ("Valeur bolean attendu mais recu: {0}" -f $data[0] )
            }

            Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Spooler" -Name Start -Value $status

        }
      
        Default { echoErr "Parametre pas pris en charge: $parameter"  }
    }   

}



if ($action -eq "read") {
    read $parameter
} elseif ( $action -eq "change" ) {
    change $parameter $remaining
}

