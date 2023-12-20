#Requires -RunAsAdministrator

# Enleve contenue si deja été installé
Remove-Item -Path "C:\Program Files\mercury" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

# Crée le dossier contenant tous les donnés importantes
New-Item -ItemType Directory -Path "C:\Program Files\mercury" | Out-Null

New-Item -ItemType Directory -Path "C:\Program Files\mercury\benchmarks" | Out-Null
New-Item -ItemType Directory -Path "C:\Program Files\mercury\manifests" | Out-Null
New-Item -ItemType Directory -Path "C:\Program Files\mercury\scripts" | Out-Null

Copy-Item -Path "..\modules\lib\lib.ps1" -Destination "C:\Program Files\mercury\scripts\lib.ps1" | Out-Null
Copy-Item -Path "..\exec\windows\mercury.exe" -Destination "C:\Program Files\mercury\mercury.exe" -Force | Out-Null
Copy-Item -Path "..\exec\windows\vcruntime140.dll" -Destination "C:\Program Files\mercury\vcruntime140.dll" -Force | Out-Null

foreach($wmodule in (Get-ChildItem "..\modules\windows")) {

    $module_path=("..\modules\windows\{0}" -f $wmodule)

    # creer un dossier pour chaque module 
    New-Item -ItemType Directory -Path ("C:\Program Files\mercury\scripts\{0}" -f $wmodule) -Force | Out-Null


    Copy-Item -Path $module_path\scripts\*.ps1 -Destination ("C:\Program Files\mercury\scripts\{0}" -f $wmodule) | Out-Null
    Copy-Item -Path $module_path\manifest.json -Destination ("C:\Program Files\mercury\manifests\{0}.json" -f $wmodule) | Out-Null
    Copy-Item -Path $module_path\*.toml -Destination ("C:\Program Files\mercury\benchmarks\{0}.toml" -f $wmodule) | Out-Null

}


# Regarde si existe déjà
$path = ([Environment]::GetEnvironmentVariable("Path", "Machine") -split ';')

if ( -not $path.Contains("C:\Program Files\mercury")) {

    $env_path= [Environment]::GetEnvironmentVariable("Path", "Machine")  + [IO.Path]::PathSeparator + "C:\Program Files\mercury"
    [Environment]::SetEnvironmentVariable( "Path", $env_path, "Machine" )

    # update la session courante
    $env:path = [Environment]::GetEnvironmentVariable("Path", "Machine")  + [IO.Path]::PathSeparator + "C:\Program Files\mercury"

}
 

# Module dependance
Install-PackageProvider NuGet -Force | Out-Null
Set-PSRepository PSGallery -InstallationPolicy Trusted | Out-Null
Install-Module -Name SecurityPolicy -AllowClobber -Force | Out-Null

New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -Force | Out-Null
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -Force | Out-Null
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'DisabledByDefault' -value '0' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null

Write-Output "Installation complété"