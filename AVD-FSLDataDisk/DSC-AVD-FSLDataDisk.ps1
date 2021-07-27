Configuration FSLDataDisk
{
    param(
        [int]$DiskNumber = 2
    )
    Import-DSCResource -ModuleName xStorage
    Import-DscResource -ModuleName AccessControlDSC
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

        NTFSAccessEntry AccessVolumeF
        {
            DependsOn = FVolume
            Path = "F:\"
            AccessControlList = @(
                NTFSAccessControlList
                {
                    Principal = "Users"
                    AccessControlEntry = @(
                        NTFSAccessControlEntry
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'Modify'
                            Inheritance = 'This folder subfolders and files'
                            Ensure = 'Present'
                        }
                    )               
                } 
            )
        }        
    }
}