Configuration PrepareHost
{
    param(
        [string[]]$VHDLocations,
        [string[]]$ExcludedMembers,
        [string[]]$IncludedMembers,
        [int]$ProfileSizeMB,
        [string]$registration,
        [string]$joinou,
        [string]$joindomain,
        [System.Management.Automation.PSCredential]$JoinCredential
    )
    
    Import-DscResource -ModuleName 'xDSCDomainjoin'
    Import-DscResource -ModuleName 'xPowerShellExecutionPolicy'

    Node localhost
    {
        Registry FSLPropertiesReg-Enabled
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'Enabled'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-DeleteLocalProfileWhenVHDShouldApply
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'DeleteLocalProfileWhenVHDShouldApply'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-FlipFlopProfileDirectoryName
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'FlipFlopProfileDirectoryName'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-IsDynamic
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'IsDynamic'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-PreventLoginWithTempProfile
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'PreventLoginWithTempProfile'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-ProfileType
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'ProfileType'
            ValueType = 'Dword'
            ValueData = '0'
        }
        Registry FSLPropertiesReg-SizeInMBs
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'SizeInMBs'
            ValueType = 'Dword'
            ValueData = $ProfileSizeMB
        }
        Registry FSLPropertiesReg-VolumeType
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'VolumeType'
            ValueType = 'String'
            ValueData = 'VHDX'
        }
        Registry FSLPropertiesReg-VHDLocations
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'VHDLocations'
            ValueType = 'MultiString'
            ValueData = $VHDLocations
        }
        if ($null -ne $ExcludedMembers) {
            Group FSLogixExclude
            {
                GroupName = "FSLogix Profile Exclude List"
                Ensure = 'Present'
                MembersToInclude = $ExcludedMembers
            }
        }
        if ($null -ne $IncludedMembers) {
            Group FSLogixInclude
            {
                GroupName = "FSLogix Profile Include List"
                Ensure = 'Present'
                Members = $IncludedMembers
            }
        }
        xPowerShellExecutionPolicy UnrestrictedExePol
        {
            ExecutionPolicy = 'Unrestricted'
        }
        Script InstallAVDAdgent{
            DependsOn = '[xPowerShellExecutionPolicy]UnrestrictedExePol'
            GetScript = {
                return @{'Result' = ''}
            }
            SetScript = {
                New-Item -Path "C:\" -Name "Temp" -ItemType "directory"
                Start-Transcript -Path "C:\Temp\wvdprep.log.txt" -Verbose -Force
                New-Item -Path "C:\" -Name "AVD" -ItemType "directory"
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile "C:\AVD\AVD-Agent.msi"
                Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile "C:\AVD\AVD-Bootloader.msi"
                Remove-Variable ProgressPreference -Force
                Start-Process -wait "C:\AVD\AVD-Agent.msi" -ArgumentList "/q RegistrationToken=$($using:registration)"
                Start-Process -wait "C:\AVD\AVD-Bootloader.msi" -ArgumentList "/q"
            }
            TestScript = {
                try {
                    $rdInfraAgentRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent"
                    
                    if (Test-path $rdInfraAgentRegistryPath) {
                        $regTokenProperties = Get-ItemProperty -Path $rdInfraAgentRegistryPath -Name "RegistrationToken"
                        $isRegisteredProperties = Get-ItemProperty -Path $rdInfraAgentRegistryPath -Name "IsRegistered"
                        return ($regTokenProperties.RegistrationToken -eq "") -and ($isRegisteredProperties.isRegistered -eq 1)
                    } else {
                        return $false;
                    }
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    throw [System.Exception]::new("Some error occurred in DSC ExecuteRdAgentInstallServer TestScript: $ErrMsg", $PSItem.Exception)
                }
            }
        }
        xDSCDomainjoin JoinDomain{
            DependsOn = '[Script]InstallAVDAdgent'
            Domain = $joindomain
            JoinOU = $joinou
            Credential = $JoinCredential
        }
    }
}