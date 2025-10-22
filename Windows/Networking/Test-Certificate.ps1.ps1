<#
.DESCRIPTION
Tests that a certificate is installed on the system
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$ScriptSettings = @{
  UploadToSyncro = $false
  SyncroAssetField = ""
  CertPath = ""
  Thumbprint = ""
  InstallType = "Machine" # Either Machine or User
  InstallLocation = "Root" # My, Root, etc.
}

$ScriptName = ([System.IO.FileInfo]$PSCommandPath).BaseName

Write-Output "Running $ScriptName with params:"
Write-Output $ScriptSettings
Write-Output "==========================="

if ($ScriptSettings.UploadToSyncro -and $env:SyncroModule) {
  Import-Module $env:SyncroModule
}

###
# Execution Logic
# Put the logic for the script here.
###

$CertPath = "cert:"
if ($ScriptSettings.InstallType -eq "Machine") {
  $CertPath += "\LocalMachine"
} else {
  $CertPath += "\CurrentUser"
}
$CertPath += "\$($ScriptSettings.InstallLocation)"

$CertPath += "\$($ScriptSettings.Thumbprint)"

$Cert = Get-ChildItem -Path "$CertPath" -ErrorAction SilentlyContinue

if ($Cert) {
  Write-Output "Found Certificate with subject: $($Cert.Subject)"
  if ($Scriptsettings.UploadToSyncro -and $env:SyncroModule) {
    Set-Asset-Field -Name "$($ScriptSettings.SyncroAssetField)" -Value $true
  }
  return $true
} else {
  Write-Output "Certificate not found"
  if ($Scriptsettings.UploadToSyncro -and $env:SyncroModule) {
    Set-Asset-Field -Name "$($ScriptSettings.SyncroAssetField)" -Value $true
  }
  return $false
}