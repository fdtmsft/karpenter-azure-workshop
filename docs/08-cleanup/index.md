# Workshop Cleanup

After completing the Karpenter Azure Workshop, you can clean up all resources created by simply deleting the resource group. This ensures you won't incur unnecessary Azure charges for resources you no longer need.

## Delete the Resource Group

Deleting the resource group is the most efficient way to remove all resources at once:

=== "Bash"
    ```bash
    # Set variable (use the same value you used during setup)
    RESOURCE_GROUP="karpenter-workshop-rg"

    # Delete the resource group
    az group delete --name $RESOURCE_GROUP --yes
    ```

=== "PowerShell"
    ```powershell
    # Set variable (use the same value you used during setup)
    $RESOURCE_GROUP="karpenter-workshop-rg"

    # Delete the resource group
    az group delete --name $RESOURCE_GROUP --yes
    ```

This command will delete the entire resource group and all resources contained within it, including:
- The AKS cluster and nodes
- All networking resources
- Any other Azure resources created as part of this workshop

!!! note
    The deletion process may take several minutes to complete. The command will block until the deletion is complete, so you'll know when all resources have been removed.

## Verification

You can verify that the resource group has been deleted:

=== "Bash"
    ```bash
    # Check if the resource group still exists
    az group show -n $RESOURCE_GROUP
    ```

=== "PowerShell"
    ```powershell
    # Check if the resource group still exists
    az group show -n $RESOURCE_GROUP
    ```

If the resource group has been successfully deleted, you'll receive an error message indicating that the resource group was not found.

Thank you for completing the Karpenter Azure Workshop! We hope you found it informative and useful for your Kubernetes scaling needs.
