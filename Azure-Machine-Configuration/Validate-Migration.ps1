# Simple validation script for Azure Machine Configuration migration
# This script performs basic validation without requiring DSC to be installed

Write-Host "Validating Azure Machine Configuration migration files..." -ForegroundColor Green

$ErrorCount = 0
$SuccessCount = 0

function Test-FileExists {
    param($FilePath, $Description)
    
    if (Test-Path $FilePath) {
        Write-Host "✓ $Description" -ForegroundColor Green
        $script:SuccessCount++
        return $true
    } else {
        Write-Host "✗ $Description - File not found: $FilePath" -ForegroundColor Red
        $script:ErrorCount++
        return $false
    }
}

function Test-JsonValidation {
    param($FilePath, $Description)
    
    if (Test-FileExists $FilePath $Description) {
        try {
            $content = Get-Content $FilePath -Raw
            $null = $content | ConvertFrom-Json
            Write-Host "✓ $Description - JSON is valid" -ForegroundColor Green
            $script:SuccessCount++
        }
        catch {
            Write-Host "✗ $Description - Invalid JSON: $($_.Exception.Message)" -ForegroundColor Red
            $script:ErrorCount++
        }
    }
}

function Test-PowerShellSyntax {
    param($FilePath, $Description)
    
    if (Test-FileExists $FilePath $Description) {
        try {
            $content = Get-Content $FilePath -Raw
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
            
            if ($errors.Count -eq 0) {
                Write-Host "✓ $Description - PowerShell syntax is valid" -ForegroundColor Green
                $script:SuccessCount++
            }
            else {
                Write-Host "✗ $Description - PowerShell syntax errors found:" -ForegroundColor Red
                foreach ($error in $errors) {
                    Write-Host "  $($error.Message)" -ForegroundColor Red
                }
                $script:ErrorCount++
            }
        }
        catch {
            Write-Host "✗ $Description - Error parsing PowerShell: $($_.Exception.Message)" -ForegroundColor Red
            $script:ErrorCount++
        }
    }
}

# Set the base path
$BasePath = Split-Path $MyInvocation.MyCommand.Path

Write-Host "`nTesting Configuration Files:" -ForegroundColor Yellow

# Test PowerShell DSC configuration files
Test-PowerShellSyntax "$BasePath\AVDHostConfiguration.ps1" "AVD Host Configuration"
Test-PowerShellSyntax "$BasePath\FSLogixConfiguration.ps1" "FSLogix Configuration"
Test-PowerShellSyntax "$BasePath\GPUConfiguration.ps1" "GPU Configuration"
Test-PowerShellSyntax "$BasePath\StorageAccountAccess.ps1" "Storage Account Access Configuration"

Write-Host "`nTesting JSON Files:" -ForegroundColor Yellow

# Test JSON files
Test-JsonValidation "$BasePath\metadata.json" "Metadata"
Test-JsonValidation "$BasePath\Policies\avd-host-configuration-policy.json" "Azure Policy Definition"
Test-JsonValidation "$BasePath\Scripts\install-avd-agent-arm-template.json" "ARM Template"

Write-Host "`nTesting Module Manifest:" -ForegroundColor Yellow

# Test module manifest
Test-PowerShellSyntax "$BasePath\AVDHostConfiguration.psd1" "Module Manifest"

Write-Host "`nTesting Scripts:" -ForegroundColor Yellow

# Test installation script
Test-PowerShellSyntax "$BasePath\Scripts\Install-AVDAgent.ps1" "AVD Agent Installation Script"

Write-Host "`nTesting Documentation:" -ForegroundColor Yellow

# Test documentation files
Test-FileExists "$BasePath\README.md" "README Documentation"

# Test specific content requirements
Write-Host "`nTesting Content Requirements:" -ForegroundColor Yellow

if (Test-Path "$BasePath\Scripts\Install-AVDAgent.ps1") {
    $scriptContent = Get-Content "$BasePath\Scripts\Install-AVDAgent.ps1" -Raw
    if ($scriptContent -match 'param\s*\(') {
        Write-Host "✓ AVD Agent script has parameters" -ForegroundColor Green
        $SuccessCount++
    } else {
        Write-Host "✗ AVD Agent script missing parameters" -ForegroundColor Red
        $ErrorCount++
    }
    
    if ($scriptContent -match '\$AvdRegistrationToken') {
        Write-Host "✓ AVD Agent script has registration token parameter" -ForegroundColor Green
        $SuccessCount++
    } else {
        Write-Host "✗ AVD Agent script missing registration token parameter" -ForegroundColor Red
        $ErrorCount++
    }
}

if (Test-Path "$BasePath\metadata.json") {
    try {
        $metadata = Get-Content "$BasePath\metadata.json" -Raw | ConvertFrom-Json
        
        $requiredProperties = @('Name', 'Version', 'Description', 'RequiredModules', 'Configurations')
        foreach ($prop in $requiredProperties) {
            if ($metadata.$prop) {
                Write-Host "✓ Metadata contains $prop" -ForegroundColor Green
                $SuccessCount++
            } else {
                Write-Host "✗ Metadata missing $prop" -ForegroundColor Red
                $ErrorCount++
            }
        }
    }
    catch {
        Write-Host "✗ Error reading metadata: $($_.Exception.Message)" -ForegroundColor Red
        $ErrorCount++
    }
}

# Summary
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan
Write-Host "Successful checks: $SuccessCount" -ForegroundColor Green
Write-Host "Failed checks: $ErrorCount" -ForegroundColor Red

if ($ErrorCount -eq 0) {
    Write-Host "`nAll validations passed! ✓" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome validations failed. Please review the errors above." -ForegroundColor Red
    exit 1
}