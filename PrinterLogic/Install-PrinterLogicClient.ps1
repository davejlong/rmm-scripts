function Install-PrinterLogicClient {
  param (
    # PrinterLogic HomeURL
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HomeURL,

    # Authorization Code
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AuthorizationCode,

    # MSI Location
    [Parameter()]
    [System.IO.FileInfo]$MsiLocation,

    # Location for temporary files
    [Parameter()]
    [System.IO.DirectoryInfo]$TempLocation,

    # Whether or not to perform an automatic checkin after installation
    [Parameter()]
    [switch]$Checkin = $false
  )


  # ----- FUNCTION DEFINITIONS
  function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  }

  function Test-PrinterLogicIsInstalled {
    $productCode = "{A9DE0858-9DDD-4E1B-B041-C2AA90DCBF74}"
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$productCode") {
      return $true
    }
    if (Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$productCode") {
      return $true
    }

    return $false
  }

  function Invoke-PrinterLogicClientInstall {
    $params = @(
      "/i"
      "$msi"
      "/qn"
      "HOMEURL=$HomeURL"
      "AUTHORIZATION_CODE=$AuthorizationCode"
    )
    if ($null -ne $TempLocation) {
      $params += "TEMPPATH=$TempLocation"
    }
    $p = Start-Process `
      -FilePath "$env:SystemRoot\system32\msiexec.exe" `
      -ArgumentList $params `
      -PassThru
    $p.WaitForExit()

    if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
      throw "Unable to install PrinterLogic Client: Error code $($p.ExitCode)"
    }
  }

  function Invoke-PrinterLogicClientUpdate {
    # To be safe, first clear out the classes registry key
    Remove-Item `
      -Path "HKLM:\SOFTWARE\PrinterLogic\PrinterInstaller\Classes" `
      -Force

    $params = @(
      "/i"
      "$msi"
      "/qn"
      "ADDLOCAL=ALL"
      "REINSTALLMODE=vomusa"
      "REINSTALL=ALL"
      "HOMEURL=$HomeURL"
      "AUTHORIZATION_CODE=$AuthorizationCode"
    )
    if ($null -ne $TempLocation) {
      $params += "TEMPPATH=$TempLocation"
    }
    $p = Start-Process `
      -FilePath "$env:SystemRoot\system32\msiexec.exe" `
      -ArgumentList $params `
      -PassThru
    $p.WaitForExit()

    if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
      throw "Unable to update PrinterLogic Client: Error code $($p.ExitCode)"
    }

    # Sleep for 5 seconds
    Start-Sleep -Seconds 5

    # Start the PrinterInstallerLauncher service
    Start-Service -Name PrinterInstallerLauncher
  }
  # ----- END FUNCTION DEFINITIONS


  # ----- MAIN SCRIPT STARTS HERE

  Write-Output "Command called with the following parameters:"
  Write-Output "  HomeURL=$HomeURL"
  Write-Output "  MsiLocation=$MsiLocation"
  Write-Output "  TempLocation=$TempLocation"
  Write-Output "  Checkin=$Checkin"

  # Make sure we are elevated
  if (!(Test-IsAdmin)) {
    $params = @(
      "-NoLogo"
      "-NoProfile"
      "-ExecutionPolicy RemoteSigned"
      "-File `"$PSCommandPath`""
      "-HomeURL $HomeURL"
      "-AuthorizationCode $AuthorizationCode"
    )
    if ($null -ne $MsiLocation) {
      $params += "-MsiLocation $MsiLocation"
    }
    if ($null -ne $TempLocation) {
      $params += "-TempLocation $TempLocation"
    }
    if ($Checkin) {
      $params += "-Checkin"
    }

    Start-Process "$($(Get-Process -id $pid | Get-Item).FullName)" -Verb RunAs -ArgumentList $params
    exit
  }

  # If the MsiLocation was specified, use that instead of downloading the latest
  if ($MsiLocation) {
    if (!(Test-Path $MsiLocation -PathType Leaf)) {
      throw "The MSI file does not exist"
    }
    $msi = $MsiLocation
  } else {
    $downloadFolder = [System.IO.Path]::GetTempPath()
    $msi = [System.IO.Path]::Combine($downloadFolder, "PrinterInstallerClient.msi")

    # Add support for TLS1.1 or TLS1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor `
      [System.Net.SecurityProtocolType]::Tls12

    # Download the latest PrinterLogic Client
    Write-Output "Downloading latest PrinterLogic client..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri https://downloads.printercloud.com/client/setup/PrinterInstallerClient.msi `
      -UseBasicParsing `
      -OutFile "$msi"
    $ProgressPreference = 'Continue'
  }

  # Install PrinterLogic
  if (!(Test-PrinterLogicIsInstalled)) {
    Write-Output "Installing PrinterLogic Client..."
    Invoke-PrinterLogicClientInstall
  }
  else {
    Write-Output "Updating PrinterLogic Client..."
    Invoke-PrinterLogicClientUpdate
  }

  # Optionally perform a checkin
  if ($Checkin) {
    $params = @("refresh")
    $p = Start-Process `
      -FilePath "C:\Program Files (x86)\Printer Properties Pro\Printer Installer Client\PrinterInstallerClient.exe" `
      -ArgumentList $params `
      -PassThru
    $p.WaitForExit()
  }
}

if ($HomeURL -and $AuthCode) {
  Install-PrinterLogicClient -HomURL $HomeURL -AuthorizationCode $AuthCode
} else {
  Write-Output "HomeURL or AuthCode missing."
}