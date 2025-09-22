<#
.DESCRIPTION
Adds a new wireless LAN profile
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$ScriptSettings = @{
  UploadToSyncro = $false
  SSID = ""
  Passphrase = ""
}

$ScriptName = ([System.IO.FileInfo]$PSCommandPath).BaseName
$OutFile = Join-Path $env:TEMP "$(Get-Date -Format FileDate)-$ScriptName.xml"

Write-Output "Running $ScriptName with params:"
Write-Output $ScriptSettings
Write-Output "==========================="

###
# Execution Logic
# Put the logic for the script here.
###

$ExistingProfile = (& netsh wlan show profiles name="$($ScriptSettings.SSID)")
if ($ExistingProfile -notlike "* is not found on the system.") {
  Write-Output "WLAN Profile already exists."
  return
}

$ProfileTemplate = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>$($ScriptSettings.SSID)</name>
  <SSIDConfig>
    <SSID>
      <name>$($ScriptSettings.SSID)</name>
    </SSID>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>auto</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>WPA3SAE</authentication>
        <encryption>AES</encryption>
        <useOneX>false</useOneX>
      </authEncryption>
      <sharedKey>
        <keyType>passPhrase</keyType>
        <protected>false</protected>
        <keyMaterial>$($ScriptSettings.Passphrase)</keyMaterial>
      </sharedKey>
    </security>
  </MSM>
  <MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
    <enableRandomization>false</enableRandomization>
  </MacRandomization>
</WLANProfile>
"@

Set-Content -Path $OutFile -Value $ProfileTemplate

# & netsh wlan add profile filename="$OutFile"

# Remove-Item $OutFile

###
# RMM Processing
###
if ($env:SyncroModule -and $ScriptSettings.UploadToSyncro) {
  Import-Module $env:SyncroModule

  Write-Output "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}