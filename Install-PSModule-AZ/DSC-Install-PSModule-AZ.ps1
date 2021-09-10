Configuration InstallPSAz
{
    Import-DscResource -Modulename PackageManagement
    
    Node localhost
    {
        PackageManagementSource PSGallery
        {
            Ensure = "Present"
            Name = "psgallery"
            ProviderName = "PowerShellGet"
            SourceLocation = "https://www.powershellgallery.com/api/v2"
            InstallationPolicy = "Trusted"
        }

        PackageManagement PSModule
        {
            Ensure = "Present"
            Name = "Az"
            Source = "PSGallery"
            MinimumVersion = "6.4.0"
            DependsOn = "[PackageManagementSource]PSGallery"
        }
    }
}