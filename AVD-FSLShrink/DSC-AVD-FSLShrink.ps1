Configuration FSLShrink
{
    param(
        [string]$ProfilesUNCPath,
        [PSCredential]$ShrinkExecuteCredential,
        [int]$ScheduleHours,
        [int]$ScheduleMinutes
    )
    $TaskArgument = "-file ""C:\Scripts\FSLShrink\Invoke-FslShrinkDisk.ps1"" -Path "+$ProfilesUNCPath+" -Recurse -PassThru -IgnoreLessThanGB 3 -LogFilePath C:\Scripts\FSLShrink\FSLShrinkLog.csv -ThrottleLimit 2 -RatioFreeSpace 0.1"
    $TaskStartTime = ([DateTime]::Today).AddHours($ScheduleHours).AddMinutes($ScheduleMinutes)
    Import-DSCResource -ModuleName 'ComputerManagementDSC'
    Import-DscResource -ModuleName 'xPowerShellExecutionPolicy'
    Import-DscResource -ModuleName 'SecurityPolicyDsc'
    node localhost{
        xPowerShellExecutionPolicy UnrestrictedExePol
        {
            ExecutionPolicy = 'Unrestricted'
        }
        Script DownloadFSLShrink
        {
            DependsOn = '[xPowerShellExecutionPolicy]UnrestrictedExePol'
            GetScript = {
                @{
                    GetScript = $GetScript
                    SetScript = $SetScript
                    TestScript = $TestScript
                    Result = (Test-Path C:\Scripts\FSLShrink\Invoke-FslShrinkDisk.ps1)
                }
            }
            SetScript = {
                if(!(test-path "c:\Scripts\"))
                {
                    New-Item -Path "C:\" -Name "Scripts" -ItemType "directory"
                }
                if(!(test-path "C:\Scripts\FSLShrink\"))
                {
                    New-Item -Path "C:\Scripts\" -Name "FSLShrink" -ItemType "directory"
                }
                if((test-path "C:\Scripts\FSLShrink\Invoke-FslShrinkDisk.ps1"))
                {
                    Remove-Item -Path "C:\Scripts\FSLShrink\Invoke-FslShrinkDisk.ps1" -Force
                }
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/FSLogix/Invoke-FslShrinkDisk/master/Invoke-FslShrinkDisk.ps1" -OutFile "C:\Scripts\FSLShrink\Invoke-FslShrinkDisk.ps1"
                Remove-Variable ProgressPreference -Force
            }
            TestScript = {
                $Status = (Test-Path C:\Scripts\FSLShrink\Invoke-FslShrinkDisk.ps1)
                $Status -eq $True
            }        
        }
        UserRightsAssignment LogonAsBatchJobShrinkUser
        {
            DependsOn = '[Script]DownloadFSLShrink'
            Policy = 'Log_on_as_a_batch_job'
            Identity = $ShrinkExecuteCredential.UserName
            Ensure = 'Present'
        }
        ScheduledTask FSLShrinkScheduledTask
        {
            DependsOn = '[UserRightsAssignment]LogonAsBatchJobShrinkUser'
            TaskName = 'Daily_FSLShrink'
            Ensure = 'Present'
            ActionExecutable = 'powershell.exe'
            ActionArguments = $TaskArgument
            ExecuteAsCredential = $ShrinkExecuteCredential
            ActionWorkingPath = 'C:\Scripts\FSLShrink\'
            ScheduleType = 'Daily'
            StartTime = $TaskStartTime
            RunLevel = 'Highest'
            LogonType = 'Password'
        }
    }
}