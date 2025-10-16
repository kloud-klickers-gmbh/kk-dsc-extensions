Configuration GPUConfiguration {
    param()

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost {
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
}