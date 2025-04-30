# Karpenter with Node Autoprovisioning Concepts

Karpenter is an open-source Kubernetes cluster autoscaler designed to improve the efficiency and cost-effectiveness of your Kubernetes workloads. It dynamically provisions and manages nodes in your cluster based on the resource requirements of your applications.

## User Roles

Karpenter serves two primary user roles:

- **Cluster Administrators**

   Responsible for installing Karpenter, configuring NodePools to set constraints for node management, and managing node disruption policies.

- **Application Developers**

   Deploy pods with specific requirements that Karpenter evaluates to provision appropriate compute resources if and when needed.

## Core Custom Resources

**NodePools**

NodePools define how Karpenter manages unschedulable pods and configures nodes. They specify:

- Constraints on what types of nodes can be provisioned
- Disruption settings for node lifecycle management
- Requirements for compute resources

You can have multiple NodePools in a cluster, each tailored for different workloads or teams.

!!! note "Karpenter NodePools and AKS NodePools"
    While having the same name, there is no link between a Karpenter NodePool and an AKS NodePool, Karpenter provisions VMs directly in the node resource group associated to the AKS cluster as single VMs.

**NodeClasses**

NodeClasses configure cloud provider-specific settings. They define characteristics such as:

- VM image selection
- VM types/sizes
- Network configuration
- Storage options

**NodeClaims**

NodeClaims are resources Karpenter uses to manage the lifecycle of Kubernetes Nodes with the underlying cloud provider. Nodeclaims ...

- Are created by Karpenter in response to provisioning and disruption needs
- Represent requests for capacity from the cloud provider
- Track the status of node creation through launch, registration, and initialization phases
- Cannot be modified directly but can be monitored to track node status
- Contain detailed information about the node's resources, conditions, labels, and cloud provider metadata


## Core Features

**Scheduling**

Karpenter launches nodes in response to pods that the Kubernetes scheduler has marked as unschedulable. It:

- Analyzes pod constraints before choosing appropriate node configurations
- Supports standard Kubernetes scheduling features (nodeAffinity, nodeSelector, etc.)
- Works with the Kubernetes scheduler to place pods on provisioned nodes

**Constraints**

Constraints determine what kinds of nodes Karpenter can provision:

- NodePool constraints set broad limits (e.g., specific VM types or zones)
- Pod constraints further refine requirements using nodeAffinity, nodeSelector, etc.
- Karpenter uses "layered constraints" - both NodePool and pod constraints must be satisfied

**Disruption**

Karpenter intelligently manages node lifecycles through several mechanisms:

- **Consolidation**: Removes or replaces nodes to reduce costs
- **Expiration**: Disrupts nodes after they reach a configured age
- **Drift**: Replaces nodes that have drifted from their desired specification
- **Interruption**: Handles cloud provider events (like spot VM interruptions)

**Cost Optimization**

Karpenter optimizes costs by:

- Provisioning appropriately sized nodes on-demand
- Consolidating workloads to reduce the total node count
- Supporting diverse VM types and purchasing options

## Difference from Cluster Autoscaler

Unlike Kubernetes Cluster Autoscaler, Karpenter:

- Handles the full flexibility of cloud providers (hundreds of VM types, zones, etc.)
- Provisions nodes directly without requiring node pools
- Can retry provisioning in milliseconds instead of minutes when capacity is unavailable

## Hosting Modes on Azure

Karpenter can be deployed on Azure Kubernetes Service (AKS) in two different modes:

1. **Node Auto Provisioning (NAP)** [Preview]
   
    Node Auto Provisioning (NAP) is a managed version of Karpenter deployed as an AKS add-on. In this mode, AKS automatically installs, configures, and manages Karpenter for you. This is the recommended approach for most users.

    Key characteristics of NAP:

    - Fully managed by AKS
    - Simplified setup with minimal configuration required
    - Automatically integrated with AKS cluster infrastructure
    - Currently in Preview status
    - Requires Azure CNI Overlay with Cilium as the network dataplane

2. **Self-hosted Mode**
   
    In self-hosted mode, you install and manage Karpenter yourself as a standalone deployment in your AKS cluster. This approach gives you more control over the Karpenter deployment and configuration.

    Key characteristics of self-hosted mode:

    - Complete control over Karpenter configuration
    - Requires more manual setup (creating identities, configuring permissions)
    - Useful for advanced users who need customization or experimentation
    - Requires management of upgrades and maintenance

## Azure-Specific Requirements and Limitations

When using Karpenter on Azure (either as NAP or self-hosted), be aware of these requirements and limitations:

1. **Applying to self-hosted and NAP**
   
    - Only Azure CNI Overlay with Cilium dataplane is supported
    - Only supports Linux nodes (Windows node pools not supported in preview)
    - Doesn't support IPv6 clusters or custom Kubelet configurations
    - Cannot be used with Service Principals (requires managed identities)

2. **Applying to NAP**
   
    - Cannot be enabled on clusters where node pools have cluster autoscaler enabled

3. **Applying to Self-Hosted**

    - Does not handle node token rotation


## Conclusion

Understanding these core concepts is essential for effectively utilizing Karpenter in your Kubernetes environment. By leveraging Karpenter's capabilities, you can enhance the scalability and efficiency of your applications while optimizing costs.

The choice between NAP and self-hosted deployment depends on your specific requirements. NAP offers simplicity and integration with AKS management, while self-hosted provides more flexibility and control.

