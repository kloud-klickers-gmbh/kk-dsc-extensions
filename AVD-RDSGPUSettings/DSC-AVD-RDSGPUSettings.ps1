Configuration RDSGPUSettings
{
    Node localhost
    {
        Registry RDSPol-HWbeforeSW
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            ValueName = 'bEnumerateHWBeforeSW'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry RDSPol-AVC444ModePref
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            ValueName = 'AVC444ModePreferred'
            ValueType = 'Dword'
            ValueData = '1'
        }
        Registry RDSPol-AVCHWEncPref
        {
            Ensure = 'Present'
            Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            ValueName = 'AVCHardwareEncodePreferred'
            ValueType = 'Dword'
            ValueData = '1'
        }
    }
}