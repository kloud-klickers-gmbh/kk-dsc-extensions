Configuration FSLDataDisk
{
    param(
        [int]$DiskNumber = 2
    )
    Import-DSCResource -ModuleName xStorage
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
    }
}