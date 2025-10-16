# Deployment Guide for Azure Machine Configuration Migration

This guide provides step-by-step instructions for deploying the new Azure Machine Configuration solution to replace the DSC Extension.

## Prerequisites

- Azure subscription with appropriate permissions
- Azure PowerShell module or Azure CLI
- Access to target Azure VMs running Windows
- Storage location for the Machine Configuration package (GitHub releases, Azure Storage, etc.)

## Step 1: Prepare the Machine Configuration Package

1. Run the package creation script:
   ```powershell
   .\Create-Package.ps1 -OutputPath "AVDHostConfiguration.zip"
   ```

2. Upload the resulting ZIP file to a publicly accessible location:
   - **GitHub Releases** (recommended): Upload to releases section of your repository
   - **Azure Storage**: Upload to a public blob container
   - **Other**: Any HTTPS-accessible location

3. Note the download URL and SHA256 hash from the package creation output.

## Step 2: Update the Azure Policy Definition

1. Open `Policies/avd-host-configuration-policy.json`

2. Update the `contentUri` field with your package URL:
   ```json
   "contentUri": "https://github.com/your-org/repo/releases/download/v1.0.0/AVDHostConfiguration.zip"
   ```

3. Update the `contentHash` field with the SHA256 hash:
   ```json
   "contentHash": "YOUR-SHA256-HASH-HERE"
   ```

## Step 3: Deploy the Azure Policy

### Using Azure PowerShell

```powershell
# Connect to Azure
Connect-AzAccount

# Set the subscription
Set-AzContext -SubscriptionId "your-subscription-id"

# Import the policy definition
$policyDef = New-AzPolicyDefinition `
    -Name "avd-host-configuration" `
    -DisplayName "Configure AVD hosts with FSLogix and GPU settings" `
    -Description "Ensures AVD hosts are configured with Azure Machine Configuration" `
    -Policy (Get-Content "Policies/avd-host-configuration-policy.json" -Raw) `
    -Mode "Indexed"

# Create policy assignment
$assignment = New-AzPolicyAssignment `
    -Name "avd-host-config-assignment" `
    -DisplayName "AVD Host Configuration Assignment" `
    -Scope "/subscriptions/your-subscription-id/resourceGroups/your-rg" `
    -PolicyDefinition $policyDef `
    -AssignIdentity `
    -Location "East US"

# Configure parameters
$parameters = @{
    EnableGPU = $true
    ProfileSizeMB = 30720
    VHDLocations = @("\\storage.file.core.windows.net\profiles")
    FSLExcludedMembers = @("Domain Admins", "Enterprise Admins")
}

Set-AzPolicyAssignment -Id $assignment.ResourceId -PolicyParameterObject $parameters
```

### Using Azure CLI

```bash
# Login to Azure
az login

# Set the subscription
az account set --subscription "your-subscription-id"

# Create policy definition
az policy definition create \
    --name "avd-host-configuration" \
    --display-name "Configure AVD hosts with FSLogix and GPU settings" \
    --description "Ensures AVD hosts are configured with Azure Machine Configuration" \
    --rules "Policies/avd-host-configuration-policy.json" \
    --mode "Indexed"

# Create policy assignment with parameters
az policy assignment create \
    --name "avd-host-config-assignment" \
    --display-name "AVD Host Configuration Assignment" \
    --scope "/subscriptions/your-subscription-id/resourceGroups/your-rg" \
    --policy "avd-host-configuration" \
    --assign-identity \
    --location "East US" \
    --params '{
        "EnableGPU": {"value": true},
        "ProfileSizeMB": {"value": 30720},
        "VHDLocations": {"value": ["\\\\storage.file.core.windows.net\\profiles"]},
        "FSLExcludedMembers": {"value": ["Domain Admins", "Enterprise Admins"]}
    }'
```

## Step 4: Handle AVD Agent Installation

Since Machine Configuration doesn't handle software installation, deploy the AVD Agent using Custom Script Extension.

### Option A: Use the provided ARM template

Deploy `Scripts/install-avd-agent-arm-template.json` with parameters:

```json
{
    "vmName": "your-vm-name",
    "avdRegistrationToken": "your-registration-token",
    "scriptUri": "https://raw.githubusercontent.com/your-org/repo/main/Azure-Machine-Configuration/Scripts/Install-AVDAgent.ps1"
}
```

### Option B: Manual Custom Script Extension

```powershell
# Create custom script extension
$vmName = "your-vm-name"
$resourceGroupName = "your-resource-group"
$scriptUri = "https://raw.githubusercontent.com/your-org/repo/main/Azure-Machine-Configuration/Scripts/Install-AVDAgent.ps1"
$registrationToken = "your-avd-registration-token"

Set-AzVMCustomScriptExtension `
    -ResourceGroupName $resourceGroupName `
    -VMName $vmName `
    -Name "InstallAVDAgent" `
    -FileUri $scriptUri `
    -Run "Install-AVDAgent.ps1" `
    -Argument "-AvdRegistrationToken `"$registrationToken`""
```

## Step 5: Configure Domain Join (if needed)

For new deployments, use Azure AD Join instead of traditional domain join:

### Azure AD Join Extension

```json
{
    "type": "Microsoft.Compute/virtualMachines/extensions",
    "name": "[concat(parameters('vmName'), '/AADLoginForWindows')]",
    "apiVersion": "2021-11-01",
    "location": "[parameters('location')]",
    "properties": {
        "publisher": "Microsoft.Azure.ActiveDirectory",
        "type": "AADLoginForWindows",
        "typeHandlerVersion": "1.0",
        "autoUpgradeMinorVersion": true
    }
}
```

### Traditional Domain Join (if required)

Use the existing domain join ARM template or PowerShell DSC separately from Machine Configuration.

## Step 6: Monitor and Validate

### Check Policy Compliance

1. Navigate to Azure Policy in the Azure Portal
2. Go to "Compliance" section
3. Find your "AVD Host Configuration Assignment"
4. Review compliance status for each VM

### View Guest Configuration Reports

1. Go to a VM in Azure Portal
2. Navigate to "Settings" > "Guest Configuration"  
3. Review configuration assignments and compliance status
4. View detailed reports and logs

### Troubleshoot Issues

Common log locations on VMs:
- Guest Configuration logs: `C:\ProgramData\GuestConfig\`
- DSC logs: Event Viewer > Applications and Services Logs > Microsoft > Windows > DSC
- Custom Script Extension logs: `C:\WindowsAzure\Logs\Plugins`

## Step 7: Migrate Existing VMs

For VMs currently using the old DSC Extension:

1. **Remove old DSC Extension** (after new configuration is confirmed working):
   ```powershell
   Remove-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name "KK-DSC-AVD"
   ```

2. **Apply new configuration**: The Azure Policy will automatically detect and configure non-compliant VMs

3. **Install AVD Agent** (if not already installed): Use the Custom Script Extension approach

4. **Validate configuration**: Check Azure Policy compliance and test AVD functionality

## Parameter Reference

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| EnableGPU | Boolean | No | false | Enable GPU acceleration settings |
| ProfileSizeMB | Integer | No | 30720 | FSLogix profile container size in MB |
| VHDLocations | Array | No | [] | UNC paths for FSLogix profile storage |
| FSLExcludedMembers | Array | No | ["Domain Admins", "Enterprise Admins"] | Users/groups to exclude from FSLogix |
| IncludeArcMachines | String | No | "false" | Include Azure Arc connected machines |

## Best Practices

1. **Test in development first**: Deploy to a test environment before production
2. **Monitor compliance**: Set up alerts for non-compliant resources
3. **Use managed identities**: Enable system-assigned managed identity for policy assignments
4. **Version control**: Tag your package releases and maintain version history
5. **Documentation**: Keep deployment parameters and procedures documented
6. **Backup configurations**: Maintain backup of existing configurations before migration

## Rollback Plan

If issues occur during migration:

1. **Disable policy assignment**: Temporarily disable the Azure Policy assignment
2. **Revert to DSC Extension**: Redeploy the original DSC Extension if needed
3. **Remove Machine Configuration**: Unassign guest configuration assignments
4. **Restore VMs**: Use VM restore points if available

## Support

For issues with this migration:
- Check the troubleshooting section in README.md
- Review Azure Policy compliance reports
- Check Guest Configuration logs on affected VMs
- Contact your infrastructure team or create an issue in the repository