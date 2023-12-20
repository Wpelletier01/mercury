#Requires -RunAsAdministrator

param (
    [Parameter(Mandatory)]
    [string]$action,
    [Parameter(Mandatory)]
    [string]$parameter,
    [Parameter(mandatory=$false, ValueFromRemainingArguments=$true)]$remaining
    
)

# . $PSScriptRoot\..\..\..\lib\lib.ps1


function update() {
    param(
        [string]$ura,
        [array]$accounts
    )

    $currents=((Get-UserRightsAssignment -UserRightsAssignment $ura).Name | where{$_ -notlike "NT AUTHORITY\LOCAL SERVICE" -and $_ -notlike "NT AUTHORITY\NETWORK SERVICE" })

    foreach ( $current in $currents ) {
       
        Remove-UserRightsAssignment -UserRightsAssignment $ura -Identity $current | Out-Null
    }


    foreach ($account in @($accounts -split "'")) {
        if ($account -ne " " ) {
            Add-UserRightsAssignment -UserRightsAssignment $ura -Identity "$account"
        }
    }
    

}




function read {
    param (
        [string]$parameter
    )
    
    switch ($parameter) {
        "acm-trust-caller" {
            $output=(Get-UserRightsAssignment -UserRightsAssignment SeTrustedCredManAccessPrivilege).Name
            $accounts=($output -split '\n')
            $data=""

            foreach($account in $accounts) {
                $data += ("'{0}'" -f $account)
            }

            Write-Output ($data -join ' ')
        }
        "rdp-logon-allow" {
            $output=(Get-UserRightsAssignment -UserRightsAssignment SeRemoteInteractiveLogonRight).Name
            $accounts=($output -split '\n')
            $data=""

            foreach($account in $accounts) {
                $data += ("'{0}'" -f $account)
            }

            Write-Output ($data -join ' ')
        }
        "impersonate-client" {
            
            $output=((Get-UserRightsAssignment -UserRightsAssignment SeImpersonatePrivilege).Name )
            $accounts=($output -split '\n')
            $data=""

            foreach($account in $accounts) {
                $data += ("'{0}'" -f $account)
            }

            Write-Output ($data -join ' ')
        }
        "volume-maint-task" {
            $output=(Get-UserRightsAssignment -UserRightsAssignment SeManageVolumePrivilege).Name
            $accounts=($output -split '\n')
            $data=""

            foreach($account in $accounts) {
                $data += ("'{0}'" -f $account)
            }

            Write-Output ($data -join ' ')
        }

        Default {
            echoErr "Parametre pas pris en charge: $parameter"
        }
    }

}


function change {
    param (
        [string]$parameter,
        [array]$data
    )
    
    switch ($parameter) {
        "acm-trust-caller"      { update "SeTrustedCredManAccessPrivilege"  $data }
        "rdp-logon-allow"       { update "SeRemoteInteractiveLogonRight"    $data }
        "impersonate-client"    { update "SeImpersonatePrivilege"           $data }
        "volume-maint-task"     { update "SeManageVolumePrivilege"          $data }
        Default                 { echoErr "Parametre pas pris en charge: $parameter" }
    }

}



if ($action -eq "read") {
    read $parameter
} elseif ( $action -eq "change" ) {
    change $parameter $remaining
}

