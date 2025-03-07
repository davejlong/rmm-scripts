<#
.DESCRIPTION
Overview of the description of the script
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$Params = @{
  SomeVariable = "foo bar"
}
$ScriptName = ([System.IO.FileInfo]$PSCommandPath).BaseName
$OutFile = Join-Path $env:TEMP "$(Get-Date -Format FileDate)-$ScriptName.txt"

Write-Host "Running $ScriptName with params:"
Write-Host $Params
Write-Host "==========================="

###
# Execution Logic
# Put the logic for the script here.
###




###
# RMM Processing
###
if ($env:SyncroModule) {
  Import-Module $env:SyncroModule

  Write-Host "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}