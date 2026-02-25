Configuration FSLogixConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProfileSizeMB,

        [Parameter(Mandatory = $true)]
        [string[]]$VHDLocations,

        [Parameter(Mandatory = $true)]
        [string[]]$FSLExcludedMembers
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost {
        # Enable FSLogix Profiles
        Registry FSLEnabled {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'Enabled'
            ValueType = 'Dword'
            ValueData = '1'
        }

        # Configure VHD Locations for profile storage
        Registry FSLVHDLocations {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'VHDLocations'
            ValueType = 'MultiString'
            ValueData = $VHDLocations
        }

        # Enable concurrent user sessions
        Registry FSLConcurrentUserSessions {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'ConcurrentUserSessions'
            ValueType = 'Dword'
            ValueData = '1'
        }

        # Delete local profile when VHD should apply
        Registry FSLDeleteLocalProfile {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'DeleteLocalProfileWhenVHDShouldApply'
            ValueType = 'Dword'
            ValueData = '1'
        }

        # Enable flip-flop profile directory naming
        Registry FSLFlipFlopProfileDirectory {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'FlipFlopProfileDirectoryName'
            ValueType = 'Dword'
            ValueData = '1'
        }

        # Enable dynamic VHD allocation
        Registry FSLIsDynamic {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'IsDynamic'
            ValueType = 'Dword'
            ValueData = '1'
        }

        # Do not keep local directory
        Registry FSLKeepLocalDir {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'KeepLocalDir'
            ValueType = 'Dword'
            ValueData = '0'
        }

        # Set profile type to standard
        Registry FSLProfileType {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'ProfileType'
            ValueType = 'Dword'
            ValueData = '0'
        }

        # Configure profile size
        Registry FSLSizeInMBs {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'SizeInMBs'
            ValueType = 'Dword'
            ValueData = $ProfileSizeMB
        }

        # Set volume type to VHDX
        Registry FSLVolumeType {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'VolumeType'
            ValueType = 'String'
            ValueData = 'VHDX'
        }

        # Access network as computer object
        Registry FSLAccessNetworkAsComputer {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'AccessNetworkAsComputerObject'
            ValueType = 'Dword'
            ValueData = '1'
        }

        # Prevent login with temporary profile
        Registry FSLPreventTempProfile {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            ValueName = 'PreventLoginWithTempProfile'
            ValueType = 'Dword'
            ValueData = '1'
        }

        # Enable credential loading from profile for Azure AD
        Registry AzureADLoadCredKey {
            Ensure    = 'Present'
            Key       = 'HKLM:\Software\Policies\Microsoft\AzureADAccount'
            ValueName = 'LoadCredKeyFromProfile'
            ValueType = 'Dword'
            ValueData = '1'
        }

        # Create FSLogix Profile Exclude List group
        Group FSLExcludeGroup {
            GroupName        = 'FSLogix Profile Exclude List'
            Ensure           = 'Present'
            MembersToInclude = $FSLExcludedMembers
        }
    }
}