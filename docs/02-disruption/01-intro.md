# Introduction to Disruption in Karpenter

## What is Disruption?

Disruption in Karpenter refers to the controlled termination and replacement of nodes in your Kubernetes cluster. This process is central to Karpenter's ability to optimize cluster resources, reduce costs, and maintain a healthy infrastructure.

## Why Disruption Matters

Karpenter's disruption capabilities provide several key benefits:

- **Cost Optimization**: By removing or replacing underutilized nodes
- **Resource Efficiency**: By ensuring workloads run on appropriately sized instances
- **Cluster Health**: By replacing nodes that have drifted from desired specifications

## Disruption Mechanisms

Karpenter offers several automated methods for disrupting nodes:

### 1. Consolidation

Karpenter can consolidate your cluster resources in two ways:

- **Delete underutilized nodes**: When workloads can be rescheduled to existing nodes
- **Replace nodes with more efficient options**: When multiple nodes can be consolidated to fewer, potentially cheaper nodes

### 2. Expiration

Nodes can be automatically replaced after a specified time period, allowing for:

- Regular infrastructure refresh
- Prevention of long-running infrastructure problems
- Simplified cluster upgrades

### 3. Drift Detection

As we have seen in the previous module, Karpenter detects when nodes drift from their desired state and replaces them to ensure consistency.

## The Disruption Process

When Karpenter disrupts a node, it follows this process:

1. Adds a `karpenter.sh/disrupted:NoSchedule` taint to prevent new pods from scheduling
2. Provisions replacement nodes if needed before termination
3. Uses the Kubernetes Eviction API to delete nodes gracefully, respecting pod-level controls

## Disruption Controls

Karpenter provides controls at multiple levels to ensure workload stability:

### NodePool-level Controls

- **Consolidation Policy**: Configure when nodes are eligible for consolidation:
    - `WhenEmpty`: Only consolidate empty nodes
    - `WhenEmptyOrUnderutilized`: Consolidate any underutilized nodes
- **Consolidation Timing**: Set how long Karpenter waits before consolidating
- **Disruption Budgets**: Limit how many nodes can be disrupted at once

### Pod-level Controls

- **Pod Disruption Budgets (PDBs)**: Kubernetes native way to ensure application availability
- **`karpenter.sh/do-not-disrupt` annotation**: Prevents Karpenter from evicting specific pods

## Next Steps

The next section focuses on node consolidation, one of Karpenter's key disruption mechanisms. We'll also show how workload owners can leverage pod-level controls such as Pod Disruption Budgets (PDBs) to ensure service availability during consolidation events. 
