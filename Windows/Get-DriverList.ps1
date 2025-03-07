<#
.DESCRIPTION
Builds a list of drivers loaded in the system
#>

###
# Script Settings
###

$Params = @{
}
$ScriptName = "Get-DriverList"
$OutFile = Join-Path -Path $env:TEMP -ChildPath "$(Get-Date -Format FileDate)-$ScriptName.txt"

Write-Host "Running $ScriptName with params:"
Write-Host $Params
Write-Host "======================================"

###
# Execution Logic
###
$Drivers = Get-CimInstance -ClassName Win32_SystemDriver `
  | Select-Object DisplayName,Description,@{n="Version";e={(Get-Item $_.PathName).VersionInfo.FileVersion}},PathName

Write-Host "Driver List:"
Write-Host "======================================"
$Drivers | Format-Table
Write-Host "======================================"

if (Test-Path -Path $OutFile) { Remove-Item -Path $OutFile }
$Drivers | Export-Csv -Path $OutFile
Write-Host "Driver list saved to $OutFile"

###
# RMM Processing
###
if ($env:SyncroModule) {
  Import-Module $env:SyncroModule

  Write-Host "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}