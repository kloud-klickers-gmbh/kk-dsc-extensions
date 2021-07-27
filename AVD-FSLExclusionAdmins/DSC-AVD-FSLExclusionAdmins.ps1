Configuration FSLExclusionAdmins
{
    param(
        [string[]]$ExcludedMembers
    )
    Node localhost
    {
        Group FSLogixExclude
        {
            GroupName = "FSLogix Profile Exclude List"
            Ensure = 'Present'
            MembersToInclude = $ExcludedMembers
        }
    }
}