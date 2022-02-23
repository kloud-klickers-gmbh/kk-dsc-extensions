Configuration PrepareHost
{
    param(
        [string[]]$VHDLocations,
        [int]$ProfileSizeMB,
        [string]$joinou,
        [string]$joindomain,
        [string[]]$FSLExcludedMembers,
        [System.Management.Automation.PSCredential]$JoinCredential
    )
    
    Import-DscResource -ModuleName 'xDSCDomainjoin'
    Import-DscResource -ModuleName 'xPowerShellExecutionPolicy'
    Import-DscResource -ModuleName 'xPendingReboot'
    Import-DscResource -ModuleName 'languageDSC'

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
        xDSCDomainjoin JoinDomain{
            DependsOn = '[xPowerShellExecutionPolicy]UnrestrictedExePol'
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
        Registry FSLPropertiesReg-Enabled
        {
            DependsOn = '[xPendingReboot]RebootDomJoin'
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'Enabled'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-DeleteLocalProfileWhenVHDShouldApply
        {
            DependsOn = '[xPendingReboot]RebootDomJoin'
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'DeleteLocalProfileWhenVHDShouldApply'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-FlipFlopProfileDirectoryName
        {
            DependsOn = '[xPendingReboot]RebootDomJoin'
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'FlipFlopProfileDirectoryName'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-IsDynamic
        {
            DependsOn = '[xPendingReboot]RebootDomJoin'
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'IsDynamic'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-PreventLoginWithTempProfile
        {
            DependsOn = '[xPendingReboot]RebootDomJoin'
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'PreventLoginWithTempProfile'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry FSLPropertiesReg-ProfileType
        {
            DependsOn = '[xPendingReboot]RebootDomJoin'
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'ProfileType'
            ValueType = 'Dword'
            ValueData = '0'
        }
        Registry FSLPropertiesReg-SizeInMBs
        {
            DependsOn = '[xPendingReboot]RebootDomJoin'
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'SizeInMBs'
            ValueType = 'Dword'
            ValueData = $ProfileSizeMB
        }
        Registry FSLPropertiesReg-VolumeType
        {
            DependsOn = '[xPendingReboot]RebootDomJoin'
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'VolumeType'
            ValueType = 'String'
            ValueData = 'VHDX'
        }
        Registry FSLPropertiesReg-VHDLocations
        {
            DependsOn = '[xPendingReboot]RebootDomJoin'
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'VHDLocations'
            ValueType = 'MultiString'
            ValueData = $VHDLocations
        }
        Group FSLExclude{
            DependsOn = '[xPendingReboot]RebootDomJoin'
            GroupName = 'FSLogix Profile Exclude List'
            Ensure = 'Present'
            MembersToInclude = $FSLExcludedMembers
        }
    }
}