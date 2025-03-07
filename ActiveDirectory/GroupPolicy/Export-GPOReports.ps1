<#
.DESCRIPTION
Overview of the description of the script
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$Params = @{
  ReportType = if ($ReportType) { $ReportType } else { "html" }
}
$ScriptName = ([System.IO.FileInfo]$PSCommandPath).BaseName
$OutPath = Join-Path -Path $env:TEMP -ChildPath "$(Get-Date -Format FileDate)-GPOReports"
$OutFile = Join-Path -Path $env:TEMP -ChildPath "$(Get-Date -Format FileDate)-GPOReports.zip"

Write-Host "Running $ScriptName with params:"
Write-Host (ConvertTo-Json -InputObject $Params)
Write-Host "==========================="

###
# Execution Logic
# Put the logic for the script here.
###

if (!(Get-Module -ListAvailable -Name GroupPolicy)) {
  Write-Host "Group Policy module not available."
  return
}

# Cleanup any previous run
if (Test-Path -Path $OutPath) { Remove-Item -Path $OutPath -Recurse }
New-Item -Path $OutPath -ItemType Directory

$GPOs = Get-GPO -All

Write-Host "Exporting all GPOs"
foreach ($GPO in $GPOs) {
  $Report = Join-Path -Path $OutPath -ChildPath "$($gpo.DisplayName).$($Params.ReportType)"
  Get-GpoReport -Guid $GPO.Id -ReportType $Params.ReportType -Path $Report
}

Write-Host "GPOs saved to $OutPath"

Write-Host "Creating zip file"
# Compress-Archive command wasn't available until Windows 2016...
Add-Type -AssemblyName "system.io.compression.filesystem"
[io.compression.zipfile]::CreateFromDirectory("$OutPath", "$OutFile")

###
# RMM Processing
###
if ($env:SyncroModule) {
  Import-Module $env:SyncroModule

  Write-Host "Uploading to Syncro"
  Upload-File -FilePath $OutFile
}