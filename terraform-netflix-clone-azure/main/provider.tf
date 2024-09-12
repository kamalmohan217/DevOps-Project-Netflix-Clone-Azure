provider "azurerm" {
  subscription_id = "5XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXXd"
  tenant_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXXX"
  features {
    
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = true    ### All the Resources within the Resource Group must be deleted before deleting the Resource Group.
    }
   
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}
