# Setting Up the Workshop Environment

This section guides you through setting up your environment for the Karpenter workshop on Azure. You'll deploy an AKS cluster and configure Node Auto Provisioning (NAP).

## Prerequisites

Before you begin, ensure you have:

- An active Azure subscription
- Azure CLI installed on your machine
- PowerShell (for PowerShell users) or Bash terminal

## 1. Set Up Variables

=== "Bash"

    ```bash
    # Set up variables
    RESOURCE_GROUP="karpenter-workshop-rg"
    LOCATION="swedencentral"  # Change as needed
    CLUSTER_NAME="karpenter-aks"
    ```

=== "PowerShell"

    ```powershell
    # Set up variables
    $RESOURCE_GROUP="karpenter-workshop-rg"
    $LOCATION="swedencentral"  # Change as needed
    $CLUSTER_NAME="karpenter-aks"
    ```

!!! note "Region Choice"
    For the purpose of Module 6 it is important you use a region where your subscription is allowed to deploy VMs across multiple availability zones. The default configuration uses the D family ARM64 nodes (eg D4pls nodes). You can verify the list for your subscription using `az vm list-skus --location swedencentral --resource-type virtualMachines --output table`.

## 2. Create Resource Group

=== "Bash"

    ```bash
    # Create a resource group
    az group create --name $RESOURCE_GROUP --location $LOCATION
    ```

=== "PowerShell"

    ```powershell
    # Create a resource group
    az group create --name $RESOURCE_GROUP --location $LOCATION
    ```

!!! note "Self-Hosted Option"
    At this stage you might follow the documentation in the [next section](03-self-hosted-karpenter.md) to install Karpenter in a self-hosted fashion. This is a more complex setup but currently is the only way for you to watch Karpenter logs. It is not necessary for the understanding of the workshop but is useful to understand Karpenter reasoning. If you choose to install Karpenter self-hosted, you can come back to this page on step 9. 
    
    Self-Hosted currently does not refresh the bootstrap token allowing new nodes to join the cluster, which means it will fail eventually - this should not affect the workshop if done in one setting, but be aware this is something you need to take care of to use this in your own environment in the current version.

## 3. Install and Update the AKS Preview Extension

This step is required for Node Auto Provisioning (NAP) as it's currently in preview.

=== "Bash"

    ```bash
    # Install or update the aks-preview extension
    az extension add --name aks-preview
    az extension update --name aks-preview
    ```

=== "PowerShell"

    ```powershell
    # Install or update the aks-preview extension
    az extension add --name aks-preview
    az extension update --name aks-preview
    ```

## 4. Register the Node Auto Provisioning Preview Feature

=== "Bash"

    ```bash
    # Register the NAP feature flag
    az feature register --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"
    
    # Check registration status (wait until it shows "Registered")
    az feature show --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"
    
    # Once registered, refresh the registration of the ContainerService resource provider
    az provider register --namespace Microsoft.ContainerService
    ```

=== "PowerShell"

    ```powershell
    # Register the NAP feature flag
    az feature register --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"
    
    # Check registration status (wait until it shows "Registered")
    az feature show --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"
    
    # Once registered, refresh the registration of the ContainerService resource provider
    az provider register --namespace Microsoft.ContainerService
    ```

!!! note
    The feature registration process may take a few minutes. Continue to the next step only after the feature shows as "Registered".

## 5. Create AKS Cluster with Node Auto Provisioning

Create a new AKS cluster with Node Auto Provisioning enabled. This requires the Azure CNI Overlay network with the Cilium dataplane.

=== "Bash"

    ```bash
    az aks create \
        --name $CLUSTER_NAME \
        --resource-group $RESOURCE_GROUP \
        --node-provisioning-mode Auto \
        --network-plugin azure \
        --network-plugin-mode overlay \
        --network-dataplane cilium \
        --generate-ssh-keys
    ```

=== "PowerShell"

    ```powershell
    az aks create `
        --name $CLUSTER_NAME `
        --resource-group $RESOURCE_GROUP `
        --node-provisioning-mode Auto `
        --network-plugin azure `
        --network-plugin-mode overlay `
        --network-dataplane cilium `
        --generate-ssh-keys
    ```

## 6. Connect to Your Cluster

=== "Bash"

    ```bash
    # Get credentials to connect to your cluster
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
    
    # Verify connection
    kubectl get nodes
    ```

=== "PowerShell"

    ```powershell
    # Get credentials to connect to your cluster
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
    
    # Verify connection
    kubectl get nodes
    ```

## 7. Explore NAP Configuration

After your cluster is created, you can view the Node Auto Provisioning configuration:

```bash
# View the AKS Node Class
kubectl get aksnodeclass

# View the Node Pool configuration
kubectl get nodepool
```

Contrary to the self-hosted deployment, NAP comes preinstalled with two Node Pools and an AKSNodeClass by default. 

The default nodepool is intended to be used by default for all workloads besides the system pods, while the system-surge nodepool is intended to allow for additional scaling of capacity specifically for system pods. 

Tue default nodeclass is intended as a standard nodeclass compatible with most workloads, using Ubuntu2204.

For the purpose of the workshop, and since node pools will be explained from scratch it is best to remove the default nodepool to avoid confusion

```bash
kubectl delete nodepool default
```

## 8. Monitor NAP Events

You can monitor NAP events to observe deployment and scheduling decisions:

```bash
kubectl get events -A --field-selector source=karpenter -w
```

## 9. (Optional) Install AKS Node Viewer

The AKS Node Viewer is a helpful tool for visualizing dynamic node usage within a cluster, showing the scheduled pod resource requests vs. the allocatable capacity on each node. The simplest way to install it is to download the correct binary from the project's [releases page](https://github.com/Azure/aks-node-viewer/releases/tag/v0.0.2-alpha). Alternatively you can install it directly if you have go on your system via `go install github.com/Azure/aks-node-viewer/cmd/aks-node-viewer@latest`.

If you have downloaded the binary, you can directly make it executable and run it.

You can use the Node Viewer to visualize your cluster's node resource allocation (be aware it ignores any node not created by Karpenter for the purpose of price calculation):

```bash
# Basic usage - displays CPU usage by default
aks-node-viewer

# To show both CPU and memory usage
aks-node-viewer --resources cpu,memory

# To filter nodes with specific labels (e.g., only Karpenter managed nodes)
aks-node-viewer -node-selector aks-karpenter=demo
```

The tool will provide a real-time visualization of node resources and pod allocations, which will be very useful as you test Karpenter's node provisioning capabilities throughout this workshop. 

!!! note "Pricing Information"
    Please remember the price values found in the screenshots of AKS Node Viewer throughout this workshop were a snapshot of a specific subscription, region and configuration, and are only meant for illustration purposes. You will not see the exact same values in your run of the workshop.

## Next Steps

Now that you have a working AKS cluster with Karpenter, you're ready to deploy workloads and observe how Karpenter automatically provisions the appropriate nodes based on your workload requirements.

In the next sections, we'll explore how to configure node pools, set constraints, and deploy sample workloads to demonstrate NAP's capabilities.

!!! note "AKSNodeClass API version"
    This workshop current uses the `AKSNodeClass` API version `v1alpha2` which is already deprecated in favor of v1beta1 in the self-hosted version. Please feel free to update the API version in the manifests to v1beta1 if you want to use the latest version, and it should work as expected.