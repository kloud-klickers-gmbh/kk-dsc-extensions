Configuration StorageAccountAccess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorageAccountKey,

        [Parameter(Mandatory = $true)]
        [string[]]$VHDLocations
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost {
        # Extract file server from first VHD location
        # Expected format: \\<storageaccount>.file.core.windows.net\<sharename>
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
                $list = & cmdkey.exe /list 2>&1 | Out-String
                return $list -match [regex]::Escape($target)
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