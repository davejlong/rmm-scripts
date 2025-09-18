<#
.DESCRIPTION
WIP: Sets what app should be used to open PDFs by default.
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$PDFApps = @{
  Acrobat = "Acrobat.Document.DC"
  FoxitEditor = "FoxitPhantomPDF.Document"
  Edge = "MSEdgePDF"
}

$ScriptSettings = @{
  UploadToSyncro = $false
  App = $PDFApps.Acrobat
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

$Command = @(
  "assoc"
  ".pdf=$($ScriptSettings.App)"
)
Start-Process -Wait -Passthru -FilePath cmd.exe -ArgumentList $Command

###
# RMM Processing
###
if ($env:SyncroModule -and $ScriptSettings.UploadToSyncro) {
  Import-Module $env:SyncroModule

  Write-Output "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}
