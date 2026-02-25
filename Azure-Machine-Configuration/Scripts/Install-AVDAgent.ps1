# AVD Agent Installation Script
# This script replaces the AVD Agent installation functionality from the original DSC configuration
# Use this with Azure VM Custom Script Extension or as part of VM provisioning

param(
    [Parameter(Mandatory = $true)]
    [String]$AvdRegistrationToken
)

$ErrorActionPreference = "Stop"

# Define download URIs for AVD components
$uris = @(
    @{
        outFile = "C:\AVD\Microsoft.RDInfra.RDAgent.Installer-x64.msi"
        uri     = "https://go.microsoft.com/fwlink/?linkid=2310011"
    }
    @{
        outFile = "C:\AVD\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi"
        uri     = "https://go.microsoft.com/fwlink/?linkid=2311028"
    }
)

function Write-LogMessage {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
    Add-Content -Path "C:\AVD\avd-agent-install.log" -Value "[$timestamp] $Message"
}

try {
    Write-LogMessage "Starting AVD Agent installation process"

    # Turn off progress bar to increase download speed
    $ProgressPreference = 'SilentlyContinue'

    # Create AVD folder if it doesn't exist
    if (!(Test-Path "C:\AVD\")) {
        New-Item -Path "C:\" -Name "AVD" -ItemType "directory" | Out-Null
        Write-LogMessage "Created C:\AVD directory"
    }

    # Download AVD components
    Write-LogMessage "Downloading AVD components..."
    foreach ($uri in $uris) {
        Write-LogMessage "Downloading from $($uri.uri) to $($uri.outFile)"
        
        # Get the actual download URL (follow redirects)
        $expandedUri = (Invoke-WebRequest -MaximumRedirection 0 -Uri $uri.uri -UseBasicParsing -ErrorAction SilentlyContinue).Headers.Location
        
        # Download the file
        Invoke-WebRequest -Uri $expandedUri -UseBasicParsing -OutFile $uri.outFile
        
        # Unblock the downloaded file
        Unblock-File -Path $uri.outFile
        
        Write-LogMessage "Downloaded and unblocked $($uri.outFile)"
    }

    # Install AVD Agent
    Write-LogMessage "Installing AVD Agent..."
    $retryTimeToSleepInSec = 30
    $retryCount = 0
    $maxRetries = 20
    $agentInstallSuccess = $false

    do {
        if ($retryCount -gt 0) {
            Write-LogMessage "Retry attempt $retryCount after $retryTimeToSleepInSec seconds"
            Start-Sleep -Seconds $retryTimeToSleepInSec
        }

        Write-LogMessage "Installing $($uris[0].outFile) with registration token..."
        $arguments = "/i `"$($uris[0].outFile)`" /quiet /norestart REGISTRATIONTOKEN=`"$AvdRegistrationToken`""
        $processResult = Start-Process -Wait -PassThru -FilePath "msiexec.exe" -ArgumentList $arguments

        $exitCode = $processResult.ExitCode
        Write-LogMessage "AVD Agent installation exit code: $exitCode"

        if ($exitCode -eq 0) {
            $agentInstallSuccess = $true
            break
        }
        elseif ($exitCode -eq 1618) {
            Write-LogMessage "Another installation is in progress (exit code 1618), retrying..."
        }
        else {
            Write-LogMessage "AVD Agent installation failed with exit code: $exitCode"
        }

        $retryCount++
    } while ($exitCode -eq 1618 -and $retryCount -lt $maxRetries)

    if (-not $agentInstallSuccess) {
        throw "AVD Agent installation failed after $maxRetries attempts. Last exit code: $exitCode"
    }

    # Install AVD Agent Boot Loader
    Write-LogMessage "Installing AVD Agent Boot Loader..."
    $retryCount = 0
    $bootloaderInstallSuccess = $false

    do {
        if ($retryCount -gt 0) {
            Write-LogMessage "Retry attempt $retryCount after $retryTimeToSleepInSec seconds"
            Start-Sleep -Seconds $retryTimeToSleepInSec
        }

        Write-LogMessage "Installing $($uris[1].outFile)..."
        $arguments = "/i `"$($uris[1].outFile)`" /quiet /norestart"
        $processResult = Start-Process -Wait -PassThru -FilePath "msiexec.exe" -ArgumentList $arguments

        $exitCode = $processResult.ExitCode
        Write-LogMessage "AVD Agent Boot Loader installation exit code: $exitCode"

        if ($exitCode -eq 0) {
            $bootloaderInstallSuccess = $true
            break
        }
        elseif ($exitCode -eq 1618) {
            Write-LogMessage "Another installation is in progress (exit code 1618), retrying..."
        }
        else {
            Write-LogMessage "AVD Agent Boot Loader installation failed with exit code: $exitCode"
        }

        $retryCount++
    } while ($exitCode -eq 1618 -and $retryCount -lt $maxRetries)

    if (-not $bootloaderInstallSuccess) {
        throw "AVD Agent Boot Loader installation failed after $maxRetries attempts. Last exit code: $exitCode"
    }

    # Verify installation
    Write-LogMessage "Verifying AVD Agent installation..."
    if (Test-Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent") {
        $registrationToken = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -Name "RegistrationToken" -ErrorAction SilentlyContinue).RegistrationToken
        $isRegistered = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -Name "IsRegistered" -ErrorAction SilentlyContinue).IsRegistered

        if ($registrationToken -eq "" -and $isRegistered -eq 1) {
            Write-LogMessage "AVD Agent installation and registration completed successfully"
        }
        else {
            Write-LogMessage "AVD Agent installation completed but registration status unclear. RegistrationToken: '$registrationToken', IsRegistered: '$isRegistered'"
        }
    }
    else {
        Write-LogMessage "Warning: AVD Agent registry keys not found after installation"
    }

    Write-LogMessage "AVD Agent installation process completed successfully"
}
catch {
    Write-LogMessage "Error during AVD Agent installation: $($_.Exception.Message)"
    Write-LogMessage "Stack trace: $($_.Exception.StackTrace)"
    throw
}
finally {
    # Restore progress preference
    $ProgressPreference = 'Continue'
}