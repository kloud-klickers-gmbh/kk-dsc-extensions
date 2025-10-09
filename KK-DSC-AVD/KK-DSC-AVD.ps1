Configuration InstallAVDAgent {
    param(
        [Parameter(Mandatory = $true)]
        [String] $AvdRegistrationToken
    )

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

    Script DownloadAgent {
        GetScript  = {
            @{
                GetScript  = $GetScript
                SetScript  = $SetScript
                TestScript = $TestScript
                Result     = ((Test-Path $using:uris[0].outFile) -and (test-path $using:uris[1].outFile))
            }
        }
        SetScript  = {
            # Turn off progress bar to increase speed
            $ProgressPreference = 'SilentlyContinue'

            # Create AVD folder if it doesn't exist
            if (!(Test-Path "c:\AVD\")) {
                New-Item -Path "C:\" -Name "AVD" -ItemType "directory"
            }

            Start-Transcript -Path "C:\AVD\avdprep.log.txt" -Verbose -Force

            foreach ($uri in $using:uris) {
                $expandedUri = (Invoke-WebRequest -MaximumRedirection 0 -Uri $uri.uri -UseBasicParsing -ErrorAction SilentlyContinue).Headers.Location
                Invoke-WebRequest -Uri $expandedUri -UseBasicParsing -OutFile $uri.outFile
                Unblock-File -Path $uri.outFile
            }

            Remove-Variable ProgressPreference -Force
        }
        TestScript = {
            $Status = ((Test-Path $using:uris[0].outFile) -and (test-path $using:uris[1].outFile))
            $Status -eq $True
        }        
    }
    Script InstallAVDAdgent {
        DependsOn  = '[Script]DownloadAgent'
        GetScript  = {
            @{
                GetScript  = $GetScript
                SetScript  = $SetScript
                TestScript = $TestScript
                Result     = ((Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent") -and ((Get-ItemProperty -Path hklm:SOFTWARE\Microsoft\RDInfraAgent -Name "RegistrationToken" -ErrorAction SilentlyContinue).RegistrationToken -eq "") -and (Get-ItemProperty -Path hklm:SOFTWARE\Microsoft\RDInfraAgent -Name "IsRegistered" -ErrorAction SilentlyContinue).isRegistered -eq 1)
            }
        }
        SetScript  = {
            $retryTimeToSleepInSec = 30
            $retryCount = 0
            $sts = $null
            do {                
                if ($retryCount -gt 0) {
                    Start-Sleep -Seconds $retryTimeToSleepInSec
                }

                Write-Host "Installing $($using:uris[0].outFile) ..."
                $processResult = Start-Process -Wait -Passthru -FilePath "msiexec.exe" "/i $($using:uris[0].outFile) /quiet /norestart REGISTRATIONTOKEN=`"$using:AvdRegistrationToken`""

                $sts = $processResult.ExitCode
                $retryCount++
            } while ($sts -eq 1618 -and $retryCount -lt 20)

      
            $retryTimeToSleepInSec = 30
            $retryCount = 0
            $sts = $null
            do {                
                if ($retryCount -gt 0) {
                    Start-Sleep -Seconds $retryTimeToSleepInSec
                }

                Write-Host "Installing $($using:uris[1].outFile) ..."
                $processResult = Start-Process -Wait -Passthru -FilePath "msiexec.exe" "/i $($using:uris[1].outFile) /quiet /norestart"

                $sts = $processResult.ExitCode
                $retryCount++
            } while ($sts -eq 1618 -and $retryCount -lt 20)


        }
        TestScript = {
            $Status = ((Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent") -and ((Get-ItemProperty -Path hklm:SOFTWARE\Microsoft\RDInfraAgent -Name "RegistrationToken" -ErrorAction SilentlyContinue).RegistrationToken -eq "") -and (Get-ItemProperty -Path hklm:SOFTWARE\Microsoft\RDInfraAgent -Name "IsRegistered" -ErrorAction SilentlyContinue).isRegistered -eq 1)
            $Status -eq $True
        }
    }    
}

Configuration ConfigureFSLogix {

    param(
        [Parameter(Mandatory = $true)]
        [String] $fslogixStorageAccountKey,

        [Parameter(Mandatory = $true)]
        [Int]$ProfileSizeMB,

        [Parameter(Mandatory = $true)]
        [String[]]$VHDLocations,

        [Parameter(Mandatory = $true)]
        [String[]]$FSLExcludedMembers
    )

    # Get first $VHDLocations entry and extract fileServer from it
    # $VHDLocations is expected to be like: "\\<storageaccount>.file.core.windows.net\<sharename>"
    # $fileServer will be "<storageaccount>.file.core.windows.net"
    $fileServer = ($VHDLocations[0] -split '\\')[2]
    
    # Extract storage account name from file server
    $storageAccount = ($fileServer -split '\.')[0]

    
    $user = "localhost\$($storageAccount)"


    Registry FSLPropertiesReg-Enabled {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'Enabled'
        ValueType = 'Dword'
        ValueData = '1'
    }
    Registry FSLPropertiesReg-VHDLocations {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'VHDLocations'
        ValueType = 'MultiString'
        ValueData = $VHDLocations
    }
    Registry FSLPropertiesReg-ConcurrentUserSessions {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'ConcurrentUserSessions'
        ValueType = 'Dword'
        ValueData = '1'
    }
    Registry FSLPropertiesReg-DeleteLocalProfileWhenVHDShouldApply {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'DeleteLocalProfileWhenVHDShouldApply'
        ValueType = 'Dword'
        ValueData = '1'
    }
    Registry FSLPropertiesReg-FlipFlopProfileDirectoryName {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'FlipFlopProfileDirectoryName'
        ValueType = 'Dword'
        ValueData = '1'
    }
    Registry FSLPropertiesReg-IsDynamic {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'IsDynamic'
        ValueType = 'Dword'
        ValueData = '1'
    }
    Registry FSLPropertiesReg-KeepLocalDir {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'KeepLocalDir'
        ValueType = 'Dword'
        ValueData = '0'
    }
    Registry FSLPropertiesReg-ProfileType {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'ProfileType'
        ValueType = 'Dword'
        ValueData = '0'
    }
    Registry FSLPropertiesReg-SizeInMBs {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'SizeInMBs'
        ValueType = 'Dword'
        ValueData = $ProfileSizeMB
    }
    Registry FSLPropertiesReg-VolumeType {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'VolumeType'
        ValueType = 'String'
        ValueData = 'VHDX'
    }
    Registry FSLPropertiesReg-AccessNetworkAsComputerObject {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'AccessNetworkAsComputerObject'
        ValueType = 'Dword'
        ValueData = '1'
    }
    Registry FSLPropertiesReg-PreventLoginWithTempProfile {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        ValueName = 'PreventLoginWithTempProfile'
        ValueType = 'Dword'
        ValueData = '1'
    }
    

    
    Group FSLExclude {
        GroupName        = 'FSLogix Profile Exclude List'
        Ensure           = 'Present'
        MembersToInclude = $FSLExcludedMembers
    }

    # Include credentials in the profile
    Registry AzureADAccount-LoadCredKeyFromProfile {
        Ensure    = 'Present'
        Key       = 'HKLM:\Software\Policies\Microsoft\AzureADAccount'
        ValueName = 'LoadCredKeyFromProfile'
        ValueType = 'Dword'
        ValueData = '1'
    }

    # Store credentials to access the storage account
    Script AddCmdKeyEntry {
        GetScript  = {
            @{ 
                Ensure     = 'Present';
                FileServer = $fileServer;
                UserName   = $user;
            }
        }

        TestScript = {
            $target = $fileServer.Trim() 
            # cmdkey lists entries like: "Target: domain:TERMSRV/fileserver"
            # We'll just check for the target string in cmdkey output
            $list = & cmdkey.exe /list 2>&1 | Out-String
            return $list -match [regex]::Escape($target)
        }

        SetScript  = {
            $target = $fileServer.Trim()


            try {
                # Build the cmdline. Quote values that may need quoting.
                $cmd = "cmdkey.exe /add:`"$target`" /user:`"$($user)`" /pass:`"$($fslogixStorageAccountKey)`""

                # Execute cmdkey
                $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -NoNewWindow -Wait -PassThru
                if ($proc.ExitCode -ne 0) {
                    throw "cmdkey failed with exit code $($proc.ExitCode)"
                }
            }
            finally {
                # Zero out & free the plain text memory quickly
                if ($bstr) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
                if ($plainPass) { $plainPass = $null }
            }
        }
    }

    # Disable Windows Defender Credential Guard (only needed for Windows 11 22H2)
    # Registry AzureADAccount-LoadCredKeyFromProfile {
    #     Ensure    = 'Present'
    #     Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    #     ValueName = 'LsaCfgFlags'
    #     ValueType = 'Dword'
    #     ValueData = '0'
    # }
}


Configuration ConfigureGPU {
    Registry RDSPol-HWbeforeSW {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        ValueName = 'bEnumerateHWBeforeSW'
        ValueType = 'Dword'
        ValueData = '1'
    }
    Registry RDSPol-AVC444ModePref {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        ValueName = 'AVC444ModePreferred'
        ValueType = 'Dword'
        ValueData = '1'
    }
    Registry RDSPol-AVCHWEncPref {
        Ensure    = 'Present'
        Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        ValueName = 'AVCHardwareEncodePreferred'
        ValueType = 'Dword'
        ValueData = '1'
    }
    Registry RDSPol-FPS60 {
        Ensure    = 'Present'
        Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
        ValueName = 'DWMFRAMEINTERVAL'
        ValueType = 'Dword'
        ValueData = '15'
    }
}



Configuration PrepareAvdHost
{
    param(
        [boolean]
        $entraOnly = $false,

        [boolean]
        $withGPU = $false,

        [String]
        $fslogixStorageAccountKey = $null,

        [int]
        $ProfileSizeMB = $null,

        [String[]]
        $VHDLocations = $null,

        [String[]]
        $FSLExcludedMembers = $null,

        [String]
        [AllowEmptyString()]
        $AvdRegistrationToken = $null,

        [String]
        [AllowEmptyString()]
        $joinou = $null,

        [String]
        [AllowEmptyString()]
        $joindomain = $null,

        [System.Management.Automation.PSCredential]
        $JoinCredential = $null
    )
    
    Import-DscResource -ModuleName 'xDSCDomainjoin'
    Import-DscResource -ModuleName 'xPowerShellExecutionPolicy'
    Import-DscResource -ModuleName 'xPendingReboot'

    Node localhost
    {
        xPendingReboot FirstBoot {
            Name = 'Firstboot'
        }
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }
        xPowerShellExecutionPolicy UnrestrictedExePol
        {
            DependsOn       = '[xPendingReboot]FirstBoot'
            ExecutionPolicy = 'Unrestricted'
        }

        Write-Host "AvdRegistrationToken: \"$AvdRegistrationToken\""

        
        if ($null -ne $AvdRegistrationToken -and $AvdRegistrationToken.Length -gt 10) {
            InstallAVDAgent InstallAVDAgent {
                AvdRegistrationToken = $AvdRegistrationToken
                DependsOn    = '[xPowerShellExecutionPolicy]UnrestrictedExePol'
            }
        }

        ConfigureFSLogix ConfigureFSLogix {
            fslogixStorageAccountKey = $fslogixStorageAccountKey
            ProfileSizeMB            = $ProfileSizeMB
            VHDLocations             = $VHDLocations
            FSLExcludedMembers       = $FSLExcludedMembers
            DependsOn                = '[xPowerShellExecutionPolicy]UnrestrictedExePol'
        }

        if ($withGPU) {
            ConfigureGPU ConfigureGPU {
                DependsOn = '[xPowerShellExecutionPolicy]UnrestrictedExePol'
            }
        }
        
        if (-not $entraOnly) {
            xDSCDomainjoin JoinDomain {
                DependsOn  = '[InstallAVDAgent]InstallAVDAgent'
                Domain     = $joindomain
                JoinOU     = $joinou
                Credential = $JoinCredential
            }
            xPendingReboot RebootDomJoin {
                Name      = 'DomJoinReboot'
                DependsOn = '[xDSCDomainjoin]JoinDomain'
            }
        }



        
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }        
    }
}


