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

Write-Output "Running $ScriptName with params:"
Write-Output (ConvertTo-Json -InputObject $Params)
Write-Output "==========================="

###
# Execution Logic
# Put the logic for the script here.
###

if (!(Get-Module -ListAvailable -Name GroupPolicy)) {
  Write-Output "Group Policy module not available."
  return
}

# Cleanup any previous run
if (Test-Path -Path $OutPath) { Remove-Item -Path $OutPath -Recurse }
New-Item -Path $OutPath -ItemType Directory

$GPOs = Get-GPO -All

Write-Output "Exporting all GPOs"
foreach ($GPO in $GPOs) {
  $Report = Join-Path -Path $OutPath -ChildPath "$($gpo.DisplayName).$($Params.ReportType)"
  Get-GpoReport -Guid $GPO.Id -ReportType $Params.ReportType -Path $Report
}

Write-Output "GPOs saved to $OutPath"

Write-Output "Creating zip file"
# Compress-Archive command wasn't available until Windows 2016...
Add-Type -AssemblyName "system.io.compression.filesystem"
[io.compression.zipfile]::CreateFromDirectory("$OutPath", "$OutFile")

###
# RMM Processing
###
if ($env:SyncroModule) {
  Import-Module $env:SyncroModule

  Write-Output "Uploading to Syncro"
  Upload-File -FilePath $OutFile
}