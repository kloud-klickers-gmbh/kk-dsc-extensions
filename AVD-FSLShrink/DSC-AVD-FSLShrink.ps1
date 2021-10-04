Configuration FSLShrink
{
    param(
        [string]$ProfilesUNCPath,
        [int]$ScheduleHours,
        [int]$ScheduleMinutes,
        [string]$sastarget,
        [string]$sasuser,
        [securestring]$saspass
    )
    $TaskArgument = "-file ""C:\Scripts\FSLShrink\Invoke-FslShrinkDisk.ps1"" -Path "+$ProfilesUNCPath+" -Recurse -PassThru -IgnoreLessThanGB 3 -LogFilePath C:\Scripts\FSLShrink\FSLShrinkLog.csv -ThrottleLimit 2 -RatioFreeSpace 0.1"
    $TaskStartTime = ([DateTime]::Today).AddHours($ScheduleHours).AddMinutes($ScheduleMinutes)
    Import-DSCResource -ModuleName 'ComputerManagementDSC'
    Import-DscResource -ModuleName 'xPowerShellExecutionPolicy'
    Import-DscResource -ModuleName 'SecurityPolicyDsc'
    node localhost{
        User LocalShrinkUser
        {
            UserName = 'FSLShrink'
            Password = $ShrinkUserPass
            Ensure = 'Present'
            PasswordNeverExpires = 'True'
        }
        Group SchrinkUserAdmin
        {
            DependsOn = '[User]LocalShrinkUser'
            GroupName = 'Administrators'
            MembersToInclude = 'FSLShrink'
            Ensure = 'Present'
        }
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
        Script AddSASKey
        {
            DependsOn = '[xPowerShellExecutionPolicy]UnrestrictedExePol'
            GetScript = {
                @{
                    GetScript = $GetScript
                    SetScript = $SetScript
                    TestScript = $TestScript
                    Result = (((cmd /C ("cmdkey `/list:Domain:target="+$($using:sastarget)+"`"")) -match "Keine|None").count -eq 0)
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
                if((Test-Path "C:\Scripts\FSLShrink\ShrinkCredential.xml"))
                {
                    Remove-Item -Path "C:\Scripts\FSLShrink\ShrinkCredential.xml" -Force
                }
                $saspassstring = [System.Net.NetworkCredential]::new("", $using:saspass).Password
                $argument = "cmdkey /add:`"$($using:sastarget)`" /user:`"$($using:sasuser)`" /pass:`"$($saspassstring)`""
                cmd.exe /C $argument
            }
            TestScript = {
                $Status = (((cmd /C ("cmdkey `/list:Domain:target="+$($using:sastarget)+"`"")) -match "Keine|None").count -eq 0)
                $Status -eq $True
            }        
        }        
        ScheduledTask FSLShrinkScheduledTask
        {
            DependsOn = '[Script]AddSASKey'
            TaskName = 'Daily_FSLShrink'
            Ensure = 'Present'
            ActionExecutable = 'powershell.exe'
            ActionArguments = $TaskArgument
            ActionWorkingPath = 'C:\Scripts\FSLShrink\'
            ScheduleType = 'Daily'
            StartTime = $TaskStartTime
            RunLevel = 'Highest'
            BuiltInAccount = 'SYSTEM'
        }
    }
}