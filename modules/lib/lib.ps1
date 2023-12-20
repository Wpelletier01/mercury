



function echoErr {
    param (
        [string]$msg
    )
    
    Write-Error $msg

    exit 1;

}