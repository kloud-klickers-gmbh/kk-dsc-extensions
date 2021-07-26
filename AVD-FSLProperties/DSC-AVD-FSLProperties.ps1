Configuration FSLProperties
{
    param(
        [string[]]$VHDLocations
    )
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
            ValueData = '100000'
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
    }
}

FSLProperties -output .\