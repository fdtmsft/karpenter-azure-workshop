# Karpenter on AKS Workshop

Welcome to the Karpenter on AKS Workshop! 

This workshop is designed to help you understand how Node Autoprovisioning, a feature of AKS that deploys and manages Karpenter helps you provision optimal node configurations based on your workload requirements.

## Workshop Overview

In this workshop, you will learn about the core concepts of Karpenter, how to set it up on AKS via Node Autoprovisioning, how to configure Node Pools and Node Classes, deploy workloads, and observe scaling behavior. Additionally, we will cover advanced configurations and provide resources for further learning.

Since Node Autoprovisioning is based on Karpenter, the workshop will often refer to Karpenter and its documentation when explaining various concepts.

## What You Will Learn

- **Core Concepts**: Understand the fundamental concepts behind Karpenter and how it differs from traditional Kubernetes Cluster Autoscaler.
- **NodePools and AKSNodeClass**: Learn how to configure these base Karpenter resources that define how Karpenter provisions and manages nodes.
- **Disruption and Consolidation**: Explore how Karpenter optimizes costs by consolidating workloads and handling node lifecycle.
- **Multi-Architecture Support**: Discover how to leverage both ARM64 and AMD64 architectures to optimize performance and costs.
- **Spot Instances**: Learn to deploy spot nodes to significantly reduce your AKS computing costs.
- **Team Isolation**: Configure team-specific provisioning strategies using multiple NodePools.
- **Advanced Scheduling**: Learn about zone-aware provisioning, node affinities, pod priority, and hybrid spot/on-demand workload deployments.

## Getting Started

To get started, navigate to the [Karpenter Concepts](00-workshop-intro/01-concepts.md) section to dive deeper into the core concepts of Karpenter.

Happy learning!