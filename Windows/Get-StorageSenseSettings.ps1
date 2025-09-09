<#
.DESCRIPTION
Get a report of storage sense settings on a computer
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$ScriptSettings = @{
  UploadToSyncro = $true
}

$ScriptName = ([System.IO.FileInfo]$PSCommandPath).BaseName
$OutFile = Join-Path $env:TEMP "$(Get-Date -Format FileDate)-$ScriptName.txt"

Write-Host "Running $ScriptName with settings:"
Write-Host $ScriptSettings
Write-Host "Writing output to $OutFile"
Write-Host "==========================="

###
# Execution Logic
# Put the logic for the script here.
###

$StorageSenseKeys = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy\'

$StorageSenseSched = switch ($StorageSenseKeys.'2048') {
  1 { 'Weekly' }
  7 { 'Every week' }
  30 { 'Every Month' }
  0 { 'Low Diskspace' }
  Default { 'Unknown - Could not retrieve.' }
}

$StorageSenseSettings = [PSCustomObject]@{
  'Storage Sense Enabled'         = [boolean]$StorageSenseKeys.'01'
  'Clear Temporary Files'         = [boolean]$StorageSenseKeys.'04'
  'Clear Recycler'                = [boolean]$StorageSenseKeys.'08'
  'Clear Downloads'               = [boolean]$StorageSenseKeys.'32'
  'Allow Clearing Onedrive Cache' = [boolean]$StorageSenseKeys.CloudfilePolicyConsent
  'Storage Sense schedule'        = $StorageSenseSched
  'Clear Downloads age (Days)'    = $StorageSenseKeys.'512'
  'Clear Recycle bin age (Days)'  = $StorageSenseKeys.'256'
}
$OneDriveAccountsSettings = @()

$OneDriveItems = Get-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy\OneDrive*'
foreach($OneDriveItem in $OneDriveItems) {
  $OneDriveName = $OneDriveItem.Name.Split('!')[-1].Split('|')[0]
  $OneDriveAccount = Get-ItemProperty -Path "HKCU:\Software\Microsoft\OneDrive\Accounts\$OneDriveName"
  $OneDriveKeys = Get-ItemProperty -Path $OneDriveItem.PSPath

  $OneDriveAccountsSettings += [PSCustomObject]@{
    'OneDrive Account'            = $OneDriveAccount.'DisplayName'
    'Storage Sense Enabled'       = [boolean]$OneDriveKeys.'02'
    'Clear cloud content (Days)'  = $OneDriveKeys.'128'

  }
}

$StorageSenseSettings | Format-Table
$OneDriveAccountsSettings | Format-Table


$StorageSenseSettings | Out-File -FilePath $OutFile
$OneDriveAccountsSettings | Out-File -FilePath $OutFile -Append
###
# RMM Processing
###
if ($env:SyncroModule -and $ScriptSettings.UploadToSyncro) {
  Import-Module $env:SyncroModule

  Write-Host "Uploading to Syncro"

  $StorageSenseSettings | Out-File -FilePath $OutFile
  $OneDriveAccountsSettings | Out-File -FilePath $OutFile -Append

  Upload-File -FilePath $OutFile
}