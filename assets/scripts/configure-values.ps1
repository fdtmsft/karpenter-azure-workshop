# Configure-Values.ps1
# This script interrogates the AKS cluster and Azure resources to generate
# the karpenter-values.yaml file using the karpenter-values-template.yaml file as a template.

param(
    [Parameter(Mandatory=$true)][string]$ClusterName,
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [Parameter(Mandatory=$true)][string]$KarpenterServiceAccountName,
    [Parameter(Mandatory=$true)][string]$KarpenterUserAssignedIdentityName
)

Write-Host "Configuring karpenter-values.yaml for cluster $ClusterName in resource group $ResourceGroup ..."

# Optional values through env vars:
$LogLevel = if ($env:LOG_LEVEL) { $env:LOG_LEVEL } else { "info" }

# Get AKS cluster information
$AksJson = az aks show --name $ClusterName --resource-group $ResourceGroup -o json | ConvertFrom-Json
$AzureLocation = $AksJson.location

# The "?? $null" ensures if the property doesn't exist, it returns null
# If the value returned is "none", it's from the AKS API and we return empty string
$NetworkPlugin = if ($AksJson.networkProfile.networkPlugin) {
    if ($AksJson.networkProfile.networkPlugin -eq "none") { "" } else { $AksJson.networkProfile.networkPlugin }
} else { "" }

$NetworkPluginMode = if ($AksJson.networkProfile.networkPluginMode) {
    if ($AksJson.networkProfile.networkPluginMode -eq "none") { "" } else { $AksJson.networkProfile.networkPluginMode }
} else { "" }

$NetworkPolicy = if ($AksJson.networkProfile.networkPolicy) {
    if ($AksJson.networkProfile.networkPolicy -eq "none") { "" } else { $AksJson.networkProfile.networkPolicy }
} else { "" }

$NodeIdentities = $AksJson.identityProfile.kubeletidentity.resourceId

# Get Karpenter user-assigned identity client ID
$KarpenterUserAssignedClientId = az identity show --resource-group $ResourceGroup --name $KarpenterUserAssignedIdentityName --query 'clientId' -otsv

# Get Azure resource group for node pool and subscription information
$AzureResourceGroupMC = $AksJson.nodeResourceGroup
$AzureSubscriptionId = az account show --query 'id' -otsv

# Get cluster endpoint
$ClusterEndpoint = kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

# Get bootstrap token
$TokenSecretName = kubectl get -n kube-system secrets --field-selector=type=bootstrap.kubernetes.io/token -o jsonpath='{.items[0].metadata.name}'
$TokenId = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((kubectl get -n kube-system secret $TokenSecretName -o jsonpath='{.data.token-id}')))
$TokenSecret = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((kubectl get -n kube-system secret $TokenSecretName -o jsonpath='{.data.token-secret}')))
$BootstrapToken = "$TokenId.$TokenSecret"

# Get SSH public key: This is a very naive Windows implementation
# It assumes the SSH public key is stored in the default location
# and is named id_rsa.pub. Adjust as necessary for your environment.
$SshPublicKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"
if (Test-Path $SshPublicKeyPath) {
    $SshPublicKey = "$(Get-Content $SshPublicKeyPath) azureuser"
} else {
    # Create a placeholder - actual implementation might vary
    $SshPublicKey = "ssh-rsa PLACEHOLDER azureuser"
    Write-Warning "SSH public key not found at $SshPublicKeyPath. Using placeholder value."
}

# Function to get VNET information
function Get-VnetJson {
    param(
        [string]$ResourceGroup,
        [PSObject]$AksJson
    )

    # Try to get VNET from resource group
    $vnetJson = az network vnet list --resource-group $ResourceGroup | ConvertFrom-Json
    
    if ($null -eq $vnetJson -or $vnetJson.Count -eq 0) {
        # If no VNET found, extract from subnet ID
        $subnetId = $AksJson.agentPoolProfiles[0].vnetSubnetId
        if ($subnetId) {
            $vnetId = $subnetId -replace '/subnets/[^/]*$', ''
            $vnetJson = az network vnet show --ids $vnetId | ConvertFrom-Json
            return $vnetJson
        }
    } else {
        return $vnetJson[0]
    }
    
    return $null
}

# Retrieve VNET JSON
$VnetJson = Get-VnetJson -ResourceGroup $AzureResourceGroupMC -AksJson $AksJson

# Extract properties from VNET JSON
$VnetSubnetId = $VnetJson.subnets[0].id
$VnetGuid = $VnetJson.resourceGuid

# Set all environment variables for template substitution
$env:CLUSTER_NAME = $ClusterName
$env:AZURE_LOCATION = $AzureLocation
$env:AZURE_RESOURCE_GROUP_MC = $AzureResourceGroupMC
$env:KARPENTER_SERVICE_ACCOUNT_NAME = $KarpenterServiceAccountName
$env:CLUSTER_ENDPOINT = $ClusterEndpoint
$env:BOOTSTRAP_TOKEN = $BootstrapToken
$env:SSH_PUBLIC_KEY = $SshPublicKey
$env:VNET_SUBNET_ID = $VnetSubnetId
$env:KARPENTER_USER_ASSIGNED_CLIENT_ID = $KarpenterUserAssignedClientId
$env:NODE_IDENTITIES = $NodeIdentities
$env:AZURE_SUBSCRIPTION_ID = $AzureSubscriptionId
$env:NETWORK_PLUGIN = $NetworkPlugin
$env:NETWORK_PLUGIN_MODE = $NetworkPluginMode
$env:NETWORK_POLICY = $NetworkPolicy
$env:LOG_LEVEL = $LogLevel
$env:VNET_GUID = $VnetGuid

# Get karpenter-values-template.yaml, if not already present
if (-not (Test-Path karpenter-values-template.yaml)) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure/karpenter/v0.7.5/karpenter-values-template.yaml" -OutFile "karpenter-values-template.yaml"
}

# Substitute environment variables in the template
$templateContent = Get-Content -Path "karpenter-values-template.yaml" -Raw
$environmentVars = Get-ChildItem -Path Env:* | Where-Object { $_.Name -in @(
    "CLUSTER_NAME", "AZURE_LOCATION", "AZURE_RESOURCE_GROUP_MC", "KARPENTER_SERVICE_ACCOUNT_NAME",
    "CLUSTER_ENDPOINT", "BOOTSTRAP_TOKEN", "SSH_PUBLIC_KEY", "VNET_SUBNET_ID",
    "KARPENTER_USER_ASSIGNED_CLIENT_ID", "NODE_IDENTITIES", "AZURE_SUBSCRIPTION_ID",
    "NETWORK_PLUGIN", "NETWORK_PLUGIN_MODE", "NETWORK_POLICY", "LOG_LEVEL", "VNET_GUID"
)}

foreach ($var in $environmentVars) {
    $placeholder = "`${" + $var.Name + "}"
    $templateContent = $templateContent -replace [regex]::Escape($placeholder), $var.Value
}

# Write the final values file
$templateContent | Out-File -FilePath "karpenter-values.yaml" -Encoding utf8

Write-Host "Generated karpenter-values.yaml successfully"