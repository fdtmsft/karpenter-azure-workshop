# Additional Disruption Concepts (Optional)

Karpenter provides various mechanisms to manage and control disruptions to workloads during node lifecycle events. These controls ensure workloads remain stable and minimize downtime. Below are the key disruption control options:

## 1. Expiration

Expiration configures a maximum lifetime for nodes. It is specified in the NodePool's `spec.template.spec.expireAfter` field and is persisted to created NodeClaims.

- **Use Case**: Enforce regular node recycling to maintain up-to-date configurations and security patches.
- **Behavior**: A node is expired once its lifetime exceeds the duration set in the owning NodeClaim's `spec.expireAfter` field. 
- **Configuration Changes**: Changes to `spec.template.spec.expireAfter` on the owning NodePool will not update existing NodeClaims - it will induce NodeClaim drift and the replacements will have the updated value. 
- **Maximum Node Lifetime**: Expiration can be used in conjunction with terminationGracePeriod (see below)git add to enforce a maximum Node lifetime.
- **Default Value**: By default, expireAfter is set to 720h (30 days).

## 2. TerminationGracePeriod

TerminationGracePeriod configures a maximum termination duration for nodes when being deleted. It is specified in the NodePool's `spec.template.spec.terminationGracePeriod` field and is persisted to created NodeClaims.

- **Use Case**: Enforce a maximum amount of time for node draining before forceful termination.
- **Behavior**: When a node is disrupted, the countdown for the terminationGracePeriod begins. Once this period elapses, any remaining pods will be forcibly deleted and the underlying instance terminated.
- **Maximum Node Lifetime**: When used with `expireAfter`, you can enforce an absolute maximum node lifetime: the node begins draining when `expireAfter` elapses and is forcibly terminated when `terminationGracePeriod` elapses, making the maximum lifetime the sum of these two values.
- **Drift Handling**: When terminationGracePeriod is reached, nodes can be disrupted via drift even if there are pods with blocking PDBs or other protection mechanisms, enabling critical updates like security patches.

## 3. NodePool Disruption Budgets

NodePool disruption budgets allow you to rate-limit Karpenter's disruption actions. These budgets define the maximum percentage or number of nodes that can be disrupted at a time.

- **Use Case**: Control the pace of disruptions to maintain cluster stability.
- **Configuration**: Specify disruption budgets in the NodePool configuration.

### Example: NodePool Disruption Budget
```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: example-nodepool
spec:
  disruption:
    budgets:
      - nodes: 10% # Allow up to 10% of nodes to be disrupted at a time
```

## Summary

By leveraging these disruption controls, Karpenter ensures workloads remain stable and highly available while optimizing resource usage. Proper configuration of these options can help you achieve a balance between cost efficiency and workload reliability.

For more detailed information on disruption controls, visit the [Karpenter Disruption Documentation](https://karpenter.sh/docs/concepts/disruption/#controls).
