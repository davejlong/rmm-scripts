<#
.DESCRIPTION
Exports an event log to a CSV file.

.PARAMETER LogName

.PARAMETER Path
CSV to save events to

.OUTPUTS
The exported events.
#>
function Export-WinEvent {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory)]
      [String] $LogName,
      [Parameter(Mandatory)]
      $Path
  )
  $Events = Get-WinEvent -LogName $LogName -ErrorAction SilentlyContinue
  if (!$Events) {
    Write-Output "No logs found on this machine."
    return
  }

  $Events | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
  Write-Output "Logs exported to: $Path"
  return $Events
}

###
# Script Settings
###

$ScriptSettings = @{
  LogName = "Microsoft-Windows-WLAN-AutoConfig/Operational"
}
$OutFile = Join-Path $env:TEMP "WLANLogs-$(Get-Date -Format FileDate).csv"
Export-WinEvent @ScriptSettings -Path $OutFile

if ($env:SyncroModule) {
  Import-Module $env:SyncroModule

  Upload-File -FilePath $OutFile
}