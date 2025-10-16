# Migration Guide: KK-DSC-AVD to Azure Machine Configuration

## Overview

This document provides a comprehensive guide for migrating from the traditional DSC Extension (KK-DSC-AVD) to Azure Machine Configuration (formerly Guest Configuration). Microsoft announced the deprecation of the DSC Extension, with support ending on March 31, 2028.

## Key Differences

### DSC Extension (Old Approach)
- Uses PowerShell DSC v2 with Windows PowerShell 5.1
- Deployed via ARM templates using Microsoft.Compute/virtualMachines/extensions
- One-time execution during VM provisioning
- Limited monitoring and compliance reporting
- Handles both configuration and installation tasks

### Azure Machine Configuration (New Approach)
- Uses PowerShell DSC v3 with PowerShell 7+
- Managed through Azure Policy Guest Configuration assignments
- Continuous monitoring and compliance reporting
- Automatic drift detection and remediation
- Focuses on configuration management, not software installation

## Migration Strategy

### What Stays in Machine Configuration
✅ **FSLogix Registry Configuration**
- All FSLogix profile settings
- Registry-based configurations
- Group membership management

✅ **GPU Policy Configuration**
- Terminal Services registry settings
- Hardware acceleration policies
- Frame rate configurations

✅ **Storage Account Access Configuration**
- cmdkey credential management (via Script DSC resource)
- Azure AD credential loading policies

### What Moves to Separate Solutions
❌ **AVD Agent Installation**
- **New Solution**: Use Azure VM Custom Script Extension
- **Reason**: Machine Configuration is not designed for software installation
- **Files**: `Scripts/Install-AVDAgent.ps1`, `Scripts/install-avd-agent-arm-template.json`

❌ **Domain Join Operations**
- **New Solution**: Use Azure AD Join or Hybrid Join via Intune/ARM templates
- **Reason**: Domain operations require special handling and reboots
- **Alternative**: Use built-in Azure domain join capabilities

❌ **Reboot Management**
- **New Solution**: Handled automatically by Azure Machine Configuration
- **Reason**: Machine Configuration manages reboots automatically when needed

## Implementation

### 1. Machine Configuration Files

#### Main Configuration
- `AVDHostConfiguration.ps1` - Combined configuration for FSLogix, GPU, and storage access
- `FSLogixConfiguration.ps1` - Standalone FSLogix configuration
- `GPUConfiguration.ps1` - Standalone GPU configuration
- `StorageAccountAccess.ps1` - Standalone storage access configuration

#### Policy Definition
- `Policies/avd-host-configuration-policy.json` - Azure Policy definition for enforcement

#### Metadata
- `metadata.json` - Configuration metadata and parameter definitions

### 2. Separate Installation Scripts

#### AVD Agent Installation
- `Scripts/Install-AVDAgent.ps1` - PowerShell script for AVD agent installation
- `Scripts/install-avd-agent-arm-template.json` - ARM template using Custom Script Extension

### 3. Deployment Steps

#### Step 1: Deploy Machine Configuration Package
1. Package the Machine Configuration files into a .zip archive
2. Upload to a publicly accessible location (e.g., GitHub releases, Azure Storage)
3. Update the `contentUri` in the policy definition

#### Step 2: Create Azure Policy Assignment
1. Import the policy definition into Azure Policy
2. Create policy assignment with appropriate parameters:
   - `EnableGPU`: true/false
   - `ProfileSizeMB`: Profile container size (e.g., 30720)
   - `VHDLocations`: Array of UNC paths for profile storage
   - `FSLExcludedMembers`: Users/groups to exclude from FSLogix

#### Step 3: Handle AVD Agent Installation
Option A: Use Custom Script Extension during VM provisioning
```json
{
    "type": "Microsoft.Compute/virtualMachines/extensions",
    "name": "InstallAVDAgent",
    "properties": {
        "publisher": "Microsoft.Compute",
        "type": "CustomScriptExtension",
        "protectedSettings": {
            "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File Install-AVDAgent.ps1 -AvdRegistrationToken \"TOKEN\""
        }
    }
}
```

Option B: Use the provided ARM template for streamlined deployment

#### Step 4: Configure Domain Join
For Azure AD Join:
```json
{
    "type": "Microsoft.Compute/virtualMachines/extensions",
    "name": "AADLoginForWindows",
    "properties": {
        "publisher": "Microsoft.Azure.ActiveDirectory",
        "type": "AADLoginForWindows"
    }
}
```

For Hybrid Join, use traditional domain join methods or Azure AD Connect.

## Parameter Mapping

### Original DSC Parameters → New Configuration

| Original Parameter | New Location | Notes |
|-------------------|-------------|-------|
| `$entraOnly` | Removed | Handle via Azure AD Join extension |
| `$withGPU` | `$EnableGPU` | Machine Configuration parameter |
| `$fslogixStorageAccountKey` | `$StorageAccountKey` | Machine Configuration parameter |
| `$ProfileSizeMB` | `$ProfileSizeMB` | Machine Configuration parameter |
| `$VHDLocations` | `$VHDLocations` | Machine Configuration parameter |
| `$FSLExcludedMembers` | `$FSLExcludedMembers` | Machine Configuration parameter |
| `$AvdRegistrationToken` | Script parameter | Custom Script Extension parameter |
| `$joinou` | ARM template | Domain join ARM template parameter |
| `$joindomain` | ARM template | Domain join ARM template parameter |
| `$JoinCredential` | ARM template | Domain join ARM template parameter |

## Benefits of the New Approach

### Enhanced Monitoring
- Continuous compliance monitoring
- Detailed reporting in Azure Policy
- Integration with Azure Security Center
- Automated drift detection

### Better Management
- Policy-based deployment and management
- Centralized configuration through Azure Policy
- Support for exemptions and remediation
- Integration with Azure Governance tools

### Improved Reliability
- Automatic retry mechanisms
- Better error handling and logging
- Support for multiple configuration attempts
- Reduced deployment failures

## Testing and Validation

### Prerequisites
- PowerShell 7+ on target machines
- Azure Policy Guest Configuration extension installed
- Appropriate Azure RBAC permissions

### Validation Steps
1. Deploy test VMs with the new configuration
2. Verify FSLogix registry settings are applied correctly
3. Test GPU acceleration functionality
4. Validate storage account access
5. Confirm compliance reporting in Azure Policy
6. Test drift detection and remediation

### Common Issues and Solutions

#### Issue: PSDscResources Module Not Found
**Solution**: Ensure the Machine Configuration package includes the PSDscResources module

#### Issue: Storage Access Fails
**Solution**: Verify cmdkey script execution and storage account permissions

#### Issue: GPU Settings Not Applied
**Solution**: Check target VM has GPU hardware and appropriate drivers

## Migration Timeline

### Phase 1: Preparation (Weeks 1-2)
- [ ] Test Machine Configuration in development environment
- [ ] Validate all configurations work as expected
- [ ] Create automation scripts for deployment

### Phase 2: Pilot Deployment (Weeks 3-4)
- [ ] Deploy to small subset of production VMs
- [ ] Monitor compliance and performance
- [ ] Gather feedback and make adjustments

### Phase 3: Full Migration (Weeks 5-8)
- [ ] Roll out to all AVD environments
- [ ] Decommission old DSC Extension deployments
- [ ] Update documentation and procedures

### Phase 4: Optimization (Weeks 9-12)
- [ ] Fine-tune policies and parameters
- [ ] Implement advanced monitoring
- [ ] Train operations teams on new tools

## Support and Troubleshooting

### Monitoring Tools
- Azure Policy Compliance Dashboard
- Azure Monitor Logs
- Guest Configuration Extension Logs
- PowerShell DSC Logs

### Key Log Locations
- Windows Event Logs: `Applications and Services Logs > Microsoft > Windows > DSC`
- Guest Configuration Logs: `C:\ProgramData\GuestConfig\`
- Custom Script Extension Logs: `C:\WindowsAzure\Logs\Plugins`

### Contact Information
For support with this migration, contact:
- **Team**: Kloud Klickers GmbH Infrastructure Team
- **Documentation**: This repository
- **Issues**: GitHub Issues for this repository

## Conclusion

The migration from DSC Extension to Azure Machine Configuration provides significant benefits in terms of monitoring, compliance, and management capabilities. While it requires restructuring the deployment approach, the long-term benefits and future-proofing make this migration essential before the March 2028 deadline.