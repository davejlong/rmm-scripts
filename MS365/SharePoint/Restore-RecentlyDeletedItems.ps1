<#
.DESCRIPTION
Restore items recently deleted from a Sharepoint library from the recycle
bin.
#>

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$Settings = @{
  UploadToSyncro = $false
  SiteURL = "https://contoso.sharepoint.com/sites/Engineering"
  ClientID = ""
  DeletedDate = Get-Date "2025-08-27"
  DeletedBy = "jsmith@contoso.com"
  Library = "Documents"
}

$ScriptName = ([System.IO.FileInfo]$PSCommandPath).BaseName
$OutFile = Join-Path $env:TEMP "$(Get-Date -Format FileDate)-$ScriptName.txt"

function Write-Log($Message) {
  Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm"): $Message"
}

Write-Log "Running $ScriptName with params:"
Write-Log $Settings
Write-Log "==========================="

###
# Execution Logic
# Put the logic for the script here.
###

Connect-PnpOnline -Url $SiteURL -Interactive -ClientId $ClientID

Write-Log "Getting lists of deleted and non-deleted files"
$DeletedItems = Get-PnPRecycleBinItem | Where-Object { (($_.DeletedDate -ge $DeletedDate) -and ($_.DeletedByEmail -eq $DeletedBy)) }
$Items = Get-PnpListItem -List $Library -PageSize 1000 | Select-Object -ExpandProperty FieldValues | ForEach-Object {
  [PSCustomObject]@{
    Identity = $_.GUID
    LeafName = $_.FileLeafRef
    DirName = $_.FileDirRef
    FullPath = ($_.FileRef -replace "^\/", "")
  }
}

Write-Log "Building restorable items list"
$RestoreableItems = @()
$NonrestoreableItems = @()
$DeletedItems | ForEach-Object {
  if ("$($_.DirName)/$($_.LeafName)" -in $Items.FullPath) {
    $NonrestoreableItems += $_
  } else {
    $RestoreableItems += $_
  }
}

Write-Log "Restoring files"

$Counter = [PSCustomObject]@{ Value = 0}
$GroupSize = 500

$Groups = $RestoreableItems | Group-Object -Property { [math]::Floor($Counter.Value++ / $GroupSize) }
Write-Log "Groups: $($Groups.Count)"

$Groups | ForEach-Object {
  Write-Log "Restoring group $($_.Name + 1)"
  $_.Group | Restore-PnPRecycleBinItem -Force
}

Write-Log "Done"

###
# RMM Processing
###
if ($env:SyncroModule -and $Settings.UploadToSyncro) {
  Import-Module $env:SyncroModule

  Write-Log "Uploading to Syncro"

  Upload-File -FilePath $OutFile
}