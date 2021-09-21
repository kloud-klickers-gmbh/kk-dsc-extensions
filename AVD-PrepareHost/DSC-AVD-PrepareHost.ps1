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
        [string]$joinuser,
        [securestring]$joinpassword
    )
    $JoinCredential = New-Object System.Management.Automation.PSCredential($joinuser,$joinpassword)

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
        Group FSLogixExclude
        {
            GroupName = "FSLogix Profile Exclude List"
            Ensure = 'Present'
            MembersToInclude = $ExcludedMembers
        }
        Group FSLogixInclude
        {
            GroupName = "FSLogix Profile Include List"
            Ensure = 'Present'
            Members = $IncludedMembers
        }
        Script InstallAVDAdgent{

            GetScript = {
                return @{'Result' = ''}
            }
            SetScript = {
                New-Item -Path "C:\" -Name "Temp" -ItemType "directory"
                Start-Transcript -Path "C:\Temp\wvdprep.log.txt" -Verbose -Force
                Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
                New-Item -Path "C:\" -Name "AVD" -ItemType "directory"
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile "C:\AVD\AVD-Agent.msi"
                Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile "C:\AVD\AVD-Bootloader.msi"
                Remove-Variable ProgressPreference -Force
                Start-Process -wait "C:\WVD\WVD-Agent.msi" -ArgumentList "/q RegistrationToken=$($using:registration)"
                Start-Process -wait "C:\WVD\WVD-Bootloader.msi" -ArgumentList "/q"
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
        Script JoinDomain{
            DependsOn = 'InstallAVDAdgent'
            GetScript = {
                GetScript = {
                    return @{'Result' = ''}
                }
            }
            SetScript = {
                if($joinou -ne ""){
                    Add-Computer -domainname $using:joindomain -OUPath $using:joinou -credential $using:joincredential -force
                }
                else {
                    Add-Computer -domainname $using:joindomain -credential $using:joincredential -force
                }
            }
            TestScript = {
                if((Get-WmiObject -Class Win32_ComputerSystem).partofdomain -eq $true){
                    if((Get-WmiObject -Class Win32_ComputerSystem).domain -match $using:joindomain){
                        Write-Output "Part of domain: $($using:joindomain)"
                        return $true
                    }else{
                        Write-Output "Not part of domain: $($using:joindomain)"
                        return $false
                    }
                }else{
                    Write-Output "Not domain joined"
                    return $false
                }
            }
        }
    }
}