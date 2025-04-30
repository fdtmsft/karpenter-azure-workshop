# Self-Hosted Karpenter Installation on AKS

This guide explains how to install self-hosted Karpenter on an existing AKS cluster.

## Prerequisites

Ensure you have the following tools installed:

- Azure CLI
- kubectl
- Helm
- jq (Bash only)
- yq (Bash only)

## Installation Steps

### 1. Set Environment Variables

=== "Bash"

    ```bash
    # Set environment variables
    export KARPENTER_NAMESPACE=kube-system
    export KARPENTER_VERSION=0.7.5  # Set your desired version
    ```

=== "PowerShell"

    ```powershell
    # Set environment variables
    $KARPENTER_NAMESPACE = "kube-system"
    $KARPENTER_VERSION = "0.7.5"  # Set your desired version
    ```

### 2. Create AKS Cluster

Create a new AKS cluster. This requires the Azure CNI Overlay network with the Cilium dataplane.

=== "Bash"

    ```bash
    AKS_JSON=$(az aks create \
        --name $CLUSTER_NAME \
        --resource-group $RESOURCE_GROUP \
        --node-count 3 \
        --generate-ssh-keys \
        --network-plugin azure \
        --network-plugin-mode overlay \
        --network-dataplane cilium \
        --enable-managed-identity \
        --enable-oidc-issuer \
        --enable-workload-identity)
    ```

=== "PowerShell"

    ```powershell
    $AKS_JSON = az aks create `
        --name $CLUSTER_NAME `
        --resource-group $RESOURCE_GROUP `
        --node-count 3 `
        --generate-ssh-keys `
        --network-plugin azure `
        --network-plugin-mode overlay `
        --network-dataplane cilium `
        --enable-managed-identity `
        --enable-oidc-issuer `
        --enable-workload-identity | ConvertFrom-Json
    ```

### 3. Connect to Your AKS Cluster

=== "Bash"

    ```bash
    az aks get-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existing
    ```

=== "PowerShell"

    ```powershell
    az aks get-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existings
    ```

### 3. Create the workload Managed Identity that backs the karpenter pod auth:

=== "Bash"

    ```bash
    KMSI_JSON=$(az identity create --name karpentermsi --resource-group "${RESOURCE_GROUP}" --location "${LOCATION}")
    ```

=== "PowerShell"

    ```powershell
    $KMSI_JSON = az identity create --name karpentermsi --resource-group $RESOURCE_GROUP --location $LOCATION | ConvertFrom-Json
    ```



### 4. Create Federated Credential linked to the Karpenter Service Account for Auth Usage:

=== "Bash"

    ```bash
    az identity federated-credential create --name KARPENTER_FID --identity-name karpentermsi --resource-group "${RESOURCE_GROUP}" \
    --issuer "$(jq -r ".oidcIssuerProfile.issuerUrl" <<< "$AKS_JSON")" \
    --subject system:serviceaccount:${KARPENTER_NAMESPACE}:karpenter-sa \
    --audience api://AzureADTokenExchange
    ```
=== "PowerShell"

    ```powershell
    az identity federated-credential create --name KARPENTER_FID --identity-name karpentermsi --resource-group $RESOURCE_GROUP `
    --issuer ($(az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP | ConvertFrom-Json).oidcIssuerProfile.issuerUrl) `
    --subject system:serviceaccount:${KARPENTER_NAMESPACE}:karpenter-sa `
    --audience api://AzureADTokenExchange 
    ```

### 5. Create role assignments to let Karpenter manage VMs and Network resources:

=== "Bash"
    ```bash
    KARPENTER_USER_ASSIGNED_CLIENT_ID=$(jq -r '.principalId' <<< "$KMSI_JSON")
    RG_MC=$(jq -r ".nodeResourceGroup" <<< "$AKS_JSON")
    RG_MC_RES=$(az group show --name "${RG_MC}" --query "id" -otsv)
    for role in "Virtual Machine Contributor" "Network Contributor" "Managed Identity Operator"; do
    az role assignment create --assignee "${KARPENTER_USER_ASSIGNED_CLIENT_ID}" --scope "${RG_MC_RES}" --role "$role"
    done
    ```

=== "PowerShell"

    ```powershell
    $KARPENTER_USER_ASSIGNED_CLIENT_ID = (az identity show --name karpentermsi --resource-group $RG | ConvertFrom-Json).principalId
    $RG_MC = (az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP | ConvertFrom-Json).nodeResourceGroup
    $RG_MC_RES = az group show --name $RG_MC --query "id" -otsv

    $roles = @("Virtual Machine Contributor", "Network Contributor", "Managed Identity Operator")
    foreach ($role in $roles) {
        az role assignment create --assignee $KARPENTER_USER_ASSIGNED_CLIENT_ID --scope $RG_MC_RES --role $role
    }
    ```

### 7. Download Configuration Template and Configure Helm Values

=== "Bash"

    ```bash
    # Download the specific version template
    curl -sO https://raw.githubusercontent.com/Azure/karpenter/v"$KARPENTER_VERSION"/karpenter-values-template.yaml

    # Download the configuration script
    curl -sO https://raw.githubusercontent.com/Azure/karpenter-provider-azure/v"$KARPENTER_VERSION"/hack/deploy/configure-values.sh
    chmod +x ./configure-values.sh

    # Generate the Karpenter values yaml file
    ./configure-values.sh $CLUSTER_NAME $RESOURCE_GROUP karpenter-sa karpentermsi
    ```

=== "PowerShell"

    ```powershell
    # Download the PowerShell configuration script from the workshop repo
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/fdudouet/karpenter-workshop/main/karpenter-azure-workshop/assets/scripts/configure-values.ps1" -OutFile "configure-values.ps1"

    # Download the specific version template
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure/karpenter/v${KARPENTER_VERSION}/karpenter-values-template.yaml" -OutFile "karpenter-values-template.yaml"

    # Generate the Karpenter values yaml file
    .\configure-values.ps1 -ClusterName $CLUSTER_NAME -ResourceGroup $RESOURCE_GROUP -KarpenterServiceAccountName "karpenter-sa" -KarpenterUserAssignedIdentityName "karpentermsi"
    ```

!!! note
    The PowerShell script `configure-values.ps1` is provided as part of this workshop. It performs similar functionality to the bash script, handling all the environment variable substitutions required for the template.

### 8. Install Karpenter Using Helm

=== "Bash"

    ```bash
    # Install Karpenter using Helm
    helm upgrade --install karpenter oci://mcr.microsoft.com/aks/karpenter/karpenter \
      --version "${KARPENTER_VERSION}" \
      --namespace "${KARPENTER_NAMESPACE}" \
      --create-namespace \
      --values karpenter-values.yaml \
      --set controller.resources.requests.cpu=1 \
      --set controller.resources.requests.memory=1Gi \
      --set controller.resources.limits.cpu=1 \
      --set controller.resources.limits.memory=1Gi \
      --wait
    ```

=== "PowerShell"

    ```powershell
    # Install Karpenter using Helm
    helm upgrade --install karpenter oci://mcr.microsoft.com/aks/karpenter/karpenter `
      --version "$KARPENTER_VERSION" `
      --namespace "$KARPENTER_NAMESPACE" `
      --create-namespace `
      --values karpenter-values.yaml `
      --set controller.resources.requests.cpu=1 `
      --set controller.resources.requests.memory=1Gi `
      --set controller.resources.limits.cpu=1 `
      --set controller.resources.limits.memory=1Gi `
      --wait
    ```

### 9. Verify Installation

=== "Bash"

    ```bash
    # Check if Karpenter pods are running
    kubectl get pods --namespace "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter

    # Check Karpenter logs
    kubectl logs -f -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter -c controller
    ```

=== "PowerShell"

    ```powershell
    # Check if Karpenter pods are running
    kubectl get pods --namespace "$KARPENTER_NAMESPACE" -l app.kubernetes.io/name=karpenter

    # Check Karpenter logs
    kubectl logs -f -n "$KARPENTER_NAMESPACE" -l app.kubernetes.io/name=karpenter -c controller
    ```

You can now go back to the Setup section at step 9.