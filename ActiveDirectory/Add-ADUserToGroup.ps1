<#
.DESCRIPTION
Adds a user to an AD group
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$ScriptSettings = @{
  UploadToSyncro = $false
  Username = "jsmith"
  GroupName = "Finance"
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

return

$UserFilter = "SamAccountNAme -eq '$($ScriptSettings.Username)' -or UserPrincipalName -eq '$($ScriptSettings.Username)' -or Mail -eq '$($ScriptSettings.Username)'"
$User = Get-ADUser -Filter $UserFilter
$Group = Get-ADGRoup -Identity $GroupName

if ($null -eq $User -or $null -eq $Group) {
  Write-Output "Could not find user or group."
  return
}

Add-ADGroupMember -Identity $Group.SamAccountName -Members $User.SamAccountName

###
# RMM Processing
###
if ($env:SyncroModule -and $ScriptSettings.UploadToSyncro) {
  Import-Module $env:SyncroModule

  Write-Output "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}