Configuration AVDHostConfiguration {
    param(
        [Parameter(Mandatory = $false)]
        [bool]$EnableGPU = $false,

        [Parameter(Mandatory = $false)]
        [string]$StorageAccountKey = $null,

        [Parameter(Mandatory = $false)]
        [int]$ProfileSizeMB = $null,

        [Parameter(Mandatory = $false)]
        [string[]]$VHDLocations = $null,

        [Parameter(Mandatory = $false)]
        [string[]]$FSLExcludedMembers = @()
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost {
        # Configure FSLogix if parameters are provided
        if ($ProfileSizeMB -gt 0 -and $VHDLocations -and $VHDLocations.Count -gt 0) {
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

        # Configure GPU settings if enabled
        if ($EnableGPU) {
            # Enable hardware enumeration before software
            Registry RDSHWBeforeSW {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                ValueName = 'bEnumerateHWBeforeSW'
                ValueType = 'Dword'
                ValueData = '1'
            }

            # Enable AVC444 mode preference
            Registry RDSAVC444Mode {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                ValueName = 'AVC444ModePreferred'
                ValueType = 'Dword'
                ValueData = '1'
            }

            # Enable AVC hardware encoding preference
            Registry RDSAVCHWEncode {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                ValueName = 'AVCHardwareEncodePreferred'
                ValueType = 'Dword'
                ValueData = '1'
            }

            # Configure 60 FPS frame interval
            Registry RDSFPS60 {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
                ValueName = 'DWMFRAMEINTERVAL'
                ValueType = 'Dword'
                ValueData = '15'
            }
        }

        # Configure storage account access if credentials are provided
        if ($StorageAccountKey -and $VHDLocations -and $VHDLocations.Count -gt 0) {
            # Extract file server from first VHD location
            $fileServer = ($VHDLocations[0] -split '\\')[2].Trim()
            $storageAccount = ($fileServer -split '\.')[0].Trim()
            $user = "localhost\$storageAccount"

            # Configure storage account credentials using cmdkey
            Script ConfigureStorageCredentials {
                GetScript = {
                    @{
                        Ensure = 'Present'
                        FileServer = $using:fileServer
                        UserName = $using:user
                    }
                }

                TestScript = {
                    $target = $using:fileServer
                    # Check if cmdkey entry exists for the target
                    try {
                        $list = & cmdkey.exe /list 2>&1 | Out-String
                        return $list -match [regex]::Escape($target)
                    }
                    catch {
                        Write-Verbose "Error checking cmdkey entries: $($_.Exception.Message)"
                        return $false
                    }
                }

                SetScript = {
                    $target = $using:fileServer
                    $username = $using:user
                    $password = $using:StorageAccountKey

                    try {
                        Write-Verbose "Adding cmdkey entry for $target using $username"
                        
                        # Build cmdkey arguments
                        $arguments = "/add:`"$target`" /user:`"$username`" /pass:`"$password`""
                        
                        # Execute cmdkey command
                        $process = Start-Process -FilePath "cmdkey.exe" -ArgumentList $arguments -NoNewWindow -Wait -PassThru
                        
                        if ($process.ExitCode -ne 0) {
                            throw "cmdkey failed with exit code $($process.ExitCode)"
                        }
                        
                        Write-Verbose "cmdkey executed successfully for $target"
                    }
                    catch {
                        Write-Error "Failed to configure storage credentials: $($_.Exception.Message)"
                        throw
                    }
                }
            }
        }
    }
}