<#
.DESCRIPTION
Ensures DestinationUser has the same group memberships as SourceUser. Adds or removes DestinationUser to groups. Does not make any modifications to SourceUser.

.PARAMETER SourceUsername
User that will be used as a template for group memberships.

.PARAMETER DestUsername
User that will be added or removed from groups.
#>
function Sync-ADUserGroupMemberships {
  param(
    [Parameter(Mandatory=$true)]
    [string] $SourceUsername,
    [Parameter(Mandatory=$true)]
    [string] $DestUsername
  )

  $SourceUser = Get-ADUser -Identity $SourceUsername
  $DestUser = Get-ADUser -Identity $DestUsername

  if (!$SourceUser) { Write-Output "Source User ($SourceUsername) doesn't exist"; return }
  if (!$DestUser) { Write-Output "Destination User ($DestUsername) doesn't exist"; return }

  $SourceGroups = Get-ADPrincipalGroupMembership $SourceUser
  $DestGroups = Get-ADPrincipalGroupMembership $DestUser

  Write-Output "Group Memberships for $($SourceUsername):"
  $SourceGroups | Format-Table
  Write-Output "Group Memberships for $($DestUsername):"
  $DestGroups | Format-Table

  $DiffGroups = Compare-Object -ReferenceObject $SourceGroups -DifferenceObject $DestGroups

  Write-Output "Group Differences"
  $DiffGroups | Format-Table

  foreach($Group in $DiffGroups) {
    if ($Group.SideIndicator -eq "=>") {
      Write-Output "Removing user from $($Group.InputObject.SamAccountName)"
      Add-ADGroupMembership -Identity $Group.InputObject -Members $DestUser
    } else {
      Write-Output "Adding user to $($Group.InputObject.SamAccountName)"
      Remove-ADGroupMember -Identity $Group.InputObject -Members $DestUser
    }
  }
}

###
# Script Settings
# Set variables here that will be populated by the RMM or set when running manually
###

$ScriptSettings = @{
  SourceUsername = ""
  DestUsername = ""
}

$ScriptName = "Sync-ADUserGroupMemberships"
$OutFile = Join-Path $env:TEMP "$(Get-Date -Format FileDate)-$ScriptName.txt"

Write-Output "Running $ScriptName with params:"
Write-Output ($ScriptSettings | ConvertTo-Json)
Write-Output "==========================="

Sync-ADUserGroupMemberships @ScriptSettings
