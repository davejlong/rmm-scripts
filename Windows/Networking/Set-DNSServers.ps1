<#
.DESCRIPTION
Updates the DNS servers for a network adapter
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$ScriptSettings = @{
  UploadToSyncro = $false
  DNSServer1 = "208.67.220.220"
  DNSServer2 = "1.1.1.1"
  NetAdapterName = ""
}

$ScriptName = ([System.IO.FileInfo]$PSCommandPath).BaseName
$OutFile = Join-Path $env:TEMP "$(Get-Date -Format FileDate)-$ScriptName.txt"

Write-Output "Running $ScriptName with params:"
Write-Output ($ScriptSettings | ConvertTo-Json)
Write-Output "==========================="

###
# Execution Logic
# Put the logic for the script here.
###

$NetAdapter = $null
if ($ScriptSettings.NetAdapterName -eq "") {
  $DefaultRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0"
  $NetAdapter = Get-NetAdapter -InterfaceIndex $DefaultRoute.ifIndex
} else {
  $NetAdapter = Get-NetAdapter -Name "$($ScriptSettings.NetAdapterName)"
}


$DNSServerList = @($ScriptSettings.DNSServer1, $ScriptSettings.DNSServer2)
$DNSParams = @{
  InterfaceIndex = $NetAdapter.ifIndex
  ServerAddresses = $DNSServerList
}

Set-DnsClientServerAddress @DNSParams

###
# RMM Processing
###
if ($env:SyncroModule -and $ScriptSettings.UploadToSyncro) {
  Import-Module $env:SyncroModule

  Write-Output "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}
