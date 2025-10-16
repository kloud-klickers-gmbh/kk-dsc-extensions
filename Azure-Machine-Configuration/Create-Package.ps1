# Package creation script for Azure Machine Configuration
# This script creates a package suitable for deployment with Azure Machine Configuration

param(
    [string]$OutputPath = ".\AVDHostConfiguration.zip",
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

Write-Host "Creating Azure Machine Configuration package..." -ForegroundColor Green

# Get the current directory
$SourcePath = Split-Path $MyInvocation.MyCommand.Path

# Define files to include in the package
$FilesToInclude = @(
    "AVDHostConfiguration.ps1",
    "FSLogixConfiguration.ps1", 
    "GPUConfiguration.ps1",
    "StorageAccountAccess.ps1",
    "AVDHostConfiguration.psd1",
    "metadata.json"
)

# Create temporary directory for package contents
$TempPath = Join-Path $env:TEMP "AVDHostConfiguration_$((Get-Date).Ticks)"
New-Item -Path $TempPath -ItemType Directory -Force | Out-Null

try {
    # Copy files to temp directory
    foreach ($file in $FilesToInclude) {
        $sourcefile = Join-Path $SourcePath $file
        if (Test-Path $sourcefile) {
            Copy-Item $sourcefile $TempPath -Force
            Write-Host "Added: $file" -ForegroundColor Gray
        } else {
            Write-Warning "File not found: $file"
        }
    }
    
    # Create the ZIP package
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Force
    }
    
    # Use PowerShell 5+ compression
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        Compress-Archive -Path "$TempPath\*" -DestinationPath $OutputPath -Force
    } else {
        # Fallback for older PowerShell versions
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($TempPath, $OutputPath)
    }
    
    $packageInfo = Get-Item $OutputPath
    Write-Host "`nPackage created successfully!" -ForegroundColor Green
    Write-Host "File: $($packageInfo.FullName)" -ForegroundColor Cyan
    Write-Host "Size: $([math]::Round($packageInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
    
    # Calculate hash for content verification
    $hash = Get-FileHash $OutputPath -Algorithm SHA256
    Write-Host "SHA256: $($hash.Hash)" -ForegroundColor Cyan
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Upload the package to a publicly accessible location (GitHub releases, Azure Storage, etc.)" -ForegroundColor White
    Write-Host "2. Update the 'contentUri' in the Azure Policy definition" -ForegroundColor White
    Write-Host "3. Update the 'contentHash' in the Azure Policy definition with the SHA256 hash above" -ForegroundColor White
    Write-Host "4. Import the policy definition and create assignments" -ForegroundColor White
}
finally {
    # Clean up temp directory
    if (Test-Path $TempPath) {
        Remove-Item $TempPath -Recurse -Force
    }
}