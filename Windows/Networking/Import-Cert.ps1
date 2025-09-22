<#
.DESCRIPTION
Installs a new certificate to a computer.
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$ScriptSettings = @{
  UploadToSyncro = $false
  CertPath = ""
  Thumbprint = "" # Used to test the certificate before install
  InstallType = "Machine" # Either Machine or User
  InstallLocation = "My" # My, Root, etc.
}

$ScriptName = ([System.IO.FileInfo]$PSCommandPath).BaseName
$OutFile = Join-Path $env:TEMP "$(Get-Date -Format FileDate)-$ScriptName.txt"

Write-Output "Running $ScriptName with params:"
Write-Output $ScriptSettings
Write-Output "==========================="

###
# Execution Logic
# Put the logic for the script here.
###

$CertContent = [System.IO.File]::ReadAllBytes($ScriptSettings.CertPath)
$Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($CertContent)

if ($Cert.Thumbprint -ne $ScriptSettings.Thumbprint) {
  Write-Output "Cert thumbprint ($($Cert.Thumbprint)) doesn't match expected thumbprint."
  return
}

$CertStoreLocation = "Cert:"
if ($ScriptSettings.InstallType = "Machine") {
  $CertStoreLocation += "\LocalMachine"
} else {
  $CertStoreLocation += "\CurrentUser"
}

$CertStoreLocation += "\$($ScriptSettings.InstallLocation)"

Import-Certificate -FilePath $ScriptSettings.CertPath -CertStoreLocation $CertStoreLocation

###
# RMM Processing
###
if ($env:SyncroModule -and $ScriptSettings.UploadToSyncro) {
  Import-Module $env:SyncroModule

  Write-Output "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}