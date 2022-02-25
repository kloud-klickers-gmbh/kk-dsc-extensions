Configuration PrepareHost
{
    param(
        [string]$registration,
        [string]$joinou,
        [string]$joindomain,
        [System.Management.Automation.PSCredential]$JoinCredential
    )
    
    Import-DscResource -ModuleName 'xDSCDomainjoin'
    Import-DscResource -ModuleName 'xPowerShellExecutionPolicy'
    Import-DscResource -ModuleName 'xPendingReboot'

    Node localhost
    {
        xPendingReboot FirstBoot{
            Name = 'Firstboot'
        }
        LocalConfigurationManager{
            RebootNodeIfNeeded = $true
        }
        xPowerShellExecutionPolicy UnrestrictedExePol
        {
            DependsOn = '[xPendingReboot]FirstBoot'
            ExecutionPolicy = 'Unrestricted'
        }
        Script DownloadAgent
        {
            DependsOn = '[xPowerShellExecutionPolicy]UnrestrictedExePol'
            GetScript = {
                @{
                    GetScript = $GetScript
                    SetScript = $SetScript
                    TestScript = $TestScript
                    Result = ((Test-Path C:\avd\AVD-Agent.msi) -and (test-path C:\avd\AVD-Bootloader.msi))
                }
            }
            SetScript = {
                if(!(test-path "c:\Temp\"))
                {
                    New-Item -Path "C:\" -Name "Temp" -ItemType "directory"
                }
                Start-Transcript -Path "C:\Temp\wvdprep.log.txt" -Verbose -Force
                if(!(test-path "c:\AVD\"))
                {
                    New-Item -Path "C:\" -Name "AVD" -ItemType "directory"
                }
                if((test-path "C:\AVD\AVD-Agent.msi"))
                {
                    Remove-Item -Path "C:\AVD\AVD-Agent.msi" -Force
                }
                if((test-path "C:\AVD\AVD-Bootloader.msi"))
                {
                    Remove-Item -Path "C:\AVD\AVD-Bootloader.msi" -Force
                }
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile "C:\AVD\AVD-Agent.msi"
                Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile "C:\AVD\AVD-Bootloader.msi"
                Remove-Variable ProgressPreference -Force
            }
            TestScript = {
                $Status = ((Test-Path C:\avd\AVD-Agent.msi) -and (test-path C:\avd\AVD-Bootloader.msi))
                $Status -eq $True
            }        
        }
        Script InstallAVDAdgent{
            DependsOn = '[Script]DownloadAgent'
            GetScript = {
                @{
                    GetScript = $GetScript
                    SetScript = $SetScript
                    TestScript = $TestScript
                    Result = ((Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent") -and ((Get-ItemProperty -Path hklm:SOFTWARE\Microsoft\RDInfraAgent -Name "RegistrationToken" -ErrorAction SilentlyContinue).RegistrationToken -eq "") -and (Get-ItemProperty -Path hklm:SOFTWARE\Microsoft\RDInfraAgent -Name "IsRegistered" -ErrorAction SilentlyContinue).isRegistered -eq 1)
                }
            }
            SetScript = {
                $argumentList = @("/i C:\AVD\AVD-Agent.msi", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$using:registration")                
                $retryTimeToSleepInSec = 30
                $retryCount = 0
                $sts = $null
                do {                
                    if ($retryCount -gt 0) {
                        Start-Sleep -Seconds $retryTimeToSleepInSec
                    }
                    $processResult = Start-Process -FilePath "msiexec.exe" -ArgumentList $argumentList -Wait -Passthru
                    $sts = $processResult.ExitCode
                    $retryCount++
                }while ($sts -eq 1618 -and $retryCount -lt 20)
                $argumentList = @("/i C:\AVD\AVD-Agent.msi", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$using:registration")                
                $retryTimeToSleepInSec = 30
                $retryCount = 0
                $sts = $null
                do {                
                    if ($retryCount -gt 0) {
                        Start-Sleep -Seconds $retryTimeToSleepInSec
                    }
                    $processResult = Start-Process -FilePath "msiexec.exe" -ArgumentList $argumentList -Wait -Passthru
                    $sts = $processResult.ExitCode
                    $retryCount++
                }while ($sts -eq 1618 -and $retryCount -lt 20)


                $argumentList = @("/i C:\AVD\AVD-Bootloader.msi", "/quiet", "/qn", "/norestart", "/passive")                
                $retryTimeToSleepInSec = 30
                $retryCount = 0
                $sts = $null
                do {                
                    if ($retryCount -gt 0) {
                        Start-Sleep -Seconds $retryTimeToSleepInSec
                    }
                    $processResult = Start-Process -FilePath "msiexec.exe" -ArgumentList $argumentList -Wait -Passthru
                    $sts = $processResult.ExitCode
                    $retryCount++
                }while ($sts -eq 1618 -and $retryCount -lt 20)
                $argumentList = @("/i C:\AVD\AVD-Agent.msi", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$using:registration")                
                $retryTimeToSleepInSec = 30
                $retryCount = 0
                $sts = $null
                do {                
                    if ($retryCount -gt 0) {
                        Start-Sleep -Seconds $retryTimeToSleepInSec
                    }
                    $processResult = Start-Process -FilePath "msiexec.exe" -ArgumentList $argumentList -Wait -Passthru
                    $sts = $processResult.ExitCode
                    $retryCount++
                }while ($sts -eq 1618 -and $retryCount -lt 20)

            }
            TestScript = {
                $Status = ((Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent") -and ((Get-ItemProperty -Path hklm:SOFTWARE\Microsoft\RDInfraAgent -Name "RegistrationToken" -ErrorAction SilentlyContinue).RegistrationToken -eq "") -and (Get-ItemProperty -Path hklm:SOFTWARE\Microsoft\RDInfraAgent -Name "IsRegistered" -ErrorAction SilentlyContinue).isRegistered -eq 1)
                $Status -eq $True
            }
        }        
        xDSCDomainjoin JoinDomain{
            DependsOn = '[Script]InstallAVDAdgent'
            Domain = $joindomain
            JoinOU = $joinou
            Credential = $JoinCredential
        }
        xPendingReboot RebootDomJoin{
            Name = 'DomJoinReboot'
            DependsOn = '[xDSCDomainjoin]JoinDomain'
        }
        LocalConfigurationManager{
            RebootNodeIfNeeded = $true
        }        
    }
}