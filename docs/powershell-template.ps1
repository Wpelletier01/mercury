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
    Write-Host "you read"

}


function change {
    param (
        [string]$parameter,
        [array]$data
    )
    
    Write-Host "you change"

}



if ($action -eq "read") {
    read $parameter
} elseif ( $action -eq "change" ) {
    change $parameter $remaining
}

