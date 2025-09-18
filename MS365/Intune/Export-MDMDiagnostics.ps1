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

Write-Output "Running $ScriptName with params:"
Write-Output $Settings
Write-Output "==========================="

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

Write-Output "Gathering diagnostics..." -NoNewline
$Proc = Start-Process @ProcParams

do {
  Start-Sleep -Seconds 1
  Write-Output "." -NoNewline
} while (!($Proc.HasExited))

Write-Output "Done!"

Write-Output "MDM Diagnostics report saved to $OutFile"



###
# RMM Processing
###
if ($env:SyncroModule -and $Settings.UploadToSyncro) {
  Import-Module $env:SyncroModule

  Write-Output "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}