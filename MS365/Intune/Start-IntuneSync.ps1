<#
.DESCRIPTION
Starts a sync with Intune (Access Work or School Sync). Source: https://www.scriptshare.io/s/XeroSec/Force%20Intune%20to%20Sync%20(Access%20Work%20Or%20School%20Sync)
#>

$DMClientID = (Get-ChildItem C:\ProgramData\Microsoft\DMClient).Name
Get-ScheduledTask `
  | Where-Object { $_.TaskPath -like "*$DMClientID*" -and $_.TaskName -like "Schedule #1*"} `
  | Start-ScheduledTask