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

Write-Output "Running $ScriptName with params:"
Write-Output $Params
Write-Output "======================================"

###
# Execution Logic
###
$Drivers = Get-CimInstance -ClassName Win32_SystemDriver `
  | Select-Object DisplayName,Description,@{n="Version";e={(Get-Item $_.PathName).VersionInfo.FileVersion}},PathName

Write-Output "Driver List:"
Write-Output "======================================"
$Drivers | Format-Table
Write-Output "======================================"

if (Test-Path -Path $OutFile) { Remove-Item -Path $OutFile }
$Drivers | Export-Csv -Path $OutFile
Write-Output "Driver list saved to $OutFile"

###
# RMM Processing
###
if ($env:SyncroModule) {
  Import-Module $env:SyncroModule

  Write-Output "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}