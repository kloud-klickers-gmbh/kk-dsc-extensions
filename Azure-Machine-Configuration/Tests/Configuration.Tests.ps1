# Tests for Azure Machine Configuration Migration
# These tests validate the Machine Configuration modules

Describe "FSLogix Configuration Tests" {
    Context "When FSLogix configuration is applied" {
        It "Should create FSLogix registry keys" {
            # This would be run on a target machine after configuration
            # For now, we validate the configuration compiles correctly
            
            # Import the configuration
            $configPath = Join-Path $PSScriptRoot "..\FSLogixConfiguration.ps1"
            . $configPath
            
            # Test parameters
            $testParams = @{
                ProfileSizeMB = 30720
                VHDLocations = @("\\storage.file.core.windows.net\profiles")
                FSLExcludedMembers = @("Domain Admins", "Enterprise Admins")
            }
            
            # Test that configuration compiles without errors
            { FSLogixConfiguration @testParams } | Should -Not -Throw
        }
        
        It "Should handle empty excluded members array" {
            $configPath = Join-Path $PSScriptRoot "..\FSLogixConfiguration.ps1"
            . $configPath
            
            $testParams = @{
                ProfileSizeMB = 30720
                VHDLocations = @("\\storage.file.core.windows.net\profiles")
                FSLExcludedMembers = @()
            }
            
            { FSLogixConfiguration @testParams } | Should -Not -Throw
        }
    }
}

Describe "GPU Configuration Tests" {
    Context "When GPU configuration is applied" {
        It "Should compile without parameters" {
            $configPath = Join-Path $PSScriptRoot "..\GPUConfiguration.ps1"
            . $configPath
            
            { GPUConfiguration } | Should -Not -Throw
        }
    }
}

Describe "Storage Account Access Tests" {
    Context "When storage account access is configured" {
        It "Should compile with valid parameters" {
            $configPath = Join-Path $PSScriptRoot "..\StorageAccountAccess.ps1"
            . $configPath
            
            $testParams = @{
                StorageAccountKey = "fake-key-for-testing"
                VHDLocations = @("\\teststorage.file.core.windows.net\profiles")
            }
            
            { StorageAccountAccess @testParams } | Should -Not -Throw
        }
        
        It "Should handle multiple VHD locations" {
            $configPath = Join-Path $PSScriptRoot "..\StorageAccountAccess.ps1"
            . $configPath
            
            $testParams = @{
                StorageAccountKey = "fake-key-for-testing"
                VHDLocations = @(
                    "\\storage1.file.core.windows.net\profiles",
                    "\\storage2.file.core.windows.net\profiles"
                )
            }
            
            { StorageAccountAccess @testParams } | Should -Not -Throw
        }
    }
}

Describe "AVD Host Configuration Tests" {
    Context "When complete AVD host configuration is applied" {
        It "Should compile with all parameters" {
            $configPath = Join-Path $PSScriptRoot "..\AVDHostConfiguration.ps1"
            . $configPath
            
            $testParams = @{
                EnableGPU = $true
                StorageAccountKey = "fake-key-for-testing"
                ProfileSizeMB = 30720
                VHDLocations = @("\\storage.file.core.windows.net\profiles")
                FSLExcludedMembers = @("Domain Admins")
            }
            
            { AVDHostConfiguration @testParams } | Should -Not -Throw
        }
        
        It "Should compile with minimal parameters" {
            $configPath = Join-Path $PSScriptRoot "..\AVDHostConfiguration.ps1"
            . $configPath
            
            $testParams = @{
                EnableGPU = $false
            }
            
            { AVDHostConfiguration @testParams } | Should -Not -Throw
        }
        
        It "Should compile with FSLogix parameters only" {
            $configPath = Join-Path $PSScriptRoot "..\AVDHostConfiguration.ps1"
            . $configPath
            
            $testParams = @{
                ProfileSizeMB = 20480
                VHDLocations = @("\\storage.file.core.windows.net\profiles")
                FSLExcludedMembers = @()
            }
            
            { AVDHostConfiguration @testParams } | Should -Not -Throw
        }
    }
}

Describe "Policy Definition Tests" {
    Context "When validating Azure Policy definition" {
        It "Should have valid JSON structure" {
            $policyPath = Join-Path $PSScriptRoot "..\Policies\avd-host-configuration-policy.json"
            $policyContent = Get-Content $policyPath -Raw
            
            { $policyContent | ConvertFrom-Json } | Should -Not -Throw
        }
        
        It "Should contain required policy properties" {
            $policyPath = Join-Path $PSScriptRoot "..\Policies\avd-host-configuration-policy.json"
            $policy = Get-Content $policyPath -Raw | ConvertFrom-Json
            
            $policy.properties | Should -Not -BeNullOrEmpty
            $policy.properties.displayName | Should -Not -BeNullOrEmpty
            $policy.properties.description | Should -Not -BeNullOrEmpty
            $policy.properties.policyRule | Should -Not -BeNullOrEmpty
            $policy.properties.parameters | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Installation Script Tests" {
    Context "When validating AVD Agent installation script" {
        It "Should have valid PowerShell syntax" {
            $scriptPath = Join-Path $PSScriptRoot "..\Scripts\Install-AVDAgent.ps1"
            
            # Test that the script parses without syntax errors
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        
        It "Should contain required parameters" {
            $scriptPath = Join-Path $PSScriptRoot "..\Scripts\Install-AVDAgent.ps1"
            $scriptContent = Get-Content $scriptPath -Raw
            
            $scriptContent | Should -Match "param\s*\("
            $scriptContent | Should -Match "\[Parameter\(Mandatory\s*=\s*\`$true\)\]"
            $scriptContent | Should -Match "\[String\]\s*\$AvdRegistrationToken"
        }
    }
}

Describe "ARM Template Tests" {
    Context "When validating ARM template" {
        It "Should have valid JSON structure" {
            $templatePath = Join-Path $PSScriptRoot "..\Scripts\install-avd-agent-arm-template.json"
            $templateContent = Get-Content $templatePath -Raw
            
            { $templateContent | ConvertFrom-Json } | Should -Not -Throw
        }
        
        It "Should contain required ARM template properties" {
            $templatePath = Join-Path $PSScriptRoot "..\Scripts\install-avd-agent-arm-template.json"
            $template = Get-Content $templatePath -Raw | ConvertFrom-Json
            
            $template.'$schema' | Should -Not -BeNullOrEmpty
            $template.contentVersion | Should -Not -BeNullOrEmpty
            $template.parameters | Should -Not -BeNullOrEmpty
            $template.resources | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Metadata Tests" {
    Context "When validating metadata file" {
        It "Should have valid JSON structure" {
            $metadataPath = Join-Path $PSScriptRoot "..\metadata.json"
            $metadataContent = Get-Content $metadataPath -Raw
            
            { $metadataContent | ConvertFrom-Json } | Should -Not -Throw
        }
        
        It "Should contain required metadata properties" {
            $metadataPath = Join-Path $PSScriptRoot "..\metadata.json"
            $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
            
            $metadata.Name | Should -Not -BeNullOrEmpty
            $metadata.Version | Should -Not -BeNullOrEmpty
            $metadata.Description | Should -Not -BeNullOrEmpty
            $metadata.RequiredModules | Should -Not -BeNullOrEmpty
            $metadata.Configurations | Should -Not -BeNullOrEmpty
        }
    }
}