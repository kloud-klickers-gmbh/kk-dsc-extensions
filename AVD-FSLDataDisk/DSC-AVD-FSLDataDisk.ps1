Configuration FSLDataDisk
{
    param(
        [int]$DiskNumber = 2
    )
    Import-DSCResource -ModuleName xStorage
    Import-DscResource -ModuleName cNtfsAccessControl
    Node localhost
    {
        xWaitforDisk Disk2
        {
            DiskIdType = 'Number'
            DiskId = $DiskNumber
            RetryIntervalSec = 60
            RetryCount = 3
        }

        xDisk FVolume
        {
            DiskIdType = 'Number'
            DiskId = $DiskNumber
            DriveLetter = 'F'
            FSLabel = 'FSLProfiles'
        }

        cNtfsPermissionEntry AllowUsersVolF
        {
            DependsOn = '[xDisk]FVolume'
            Ensure = 'Present'
            Path = "F:\"
            Principal = "Users"
            AccessControlInformation = @(
                cNTFSAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                }
            )
        }
          
    }
}