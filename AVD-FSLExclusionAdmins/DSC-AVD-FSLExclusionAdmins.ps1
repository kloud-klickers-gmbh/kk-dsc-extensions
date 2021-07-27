Configuration FSLDataDisk
{
    Node localhost
    {
        Group FSLogixExclude
        {
            GroupName = "FSLogix Profile Exclude List"
            Ensure = 'Present'
            MembersToInclude = @("Administrators")
        }
    }
}