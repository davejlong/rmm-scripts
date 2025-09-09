<#
.DESCRIPTION
Exports MDM diagnostics information on an Intune joined
computer. If running from Syncro, also uploads the report
to the asset in Syncro.
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$Settings = @{
  UploadToSyncro = $true
}

$ScriptName = ([System.IO.FileInfo]$PSCommandPath).BaseName
$OutFile = Join-Path $env:TEMP "$(Get-Date -Format FileDate)-$ScriptName.zip"

Write-Host "Running $ScriptName with params:"
Write-Host $Settings
Write-Host "==========================="

###
# Execution Logic
# Put the logic for the script here.
###

$ProcParams = @{
  FilePath = "$env:SystemRoot\System32\MdmDiagnosticsTool.exe"
  ArgumentList = @("-area", "'DeviceEnrollment;DeviceProvisioning;Autopilot'", "-zip", $OutFile)
  PassThru = $true
  Wait = $true
}

Write-Host "Gathering diagnostics..." -NoNewline
$Proc = Start-Process @ProcParams

do {
  Start-Sleep -Seconds 1
  Write-Host "." -NoNewline
} while (!($Proc.HasExited))

Write-Host "Done!"

Write-Host "MDM Diagnostics report saved to $OutFile"



###
# RMM Processing
###
if ($env:SyncroModule -and $Settings.UploadToSyncro) {
  Import-Module $env:SyncroModule

  Write-Host "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}