# aft-account-request

module "customer_josh" {
  source = "./modules/aft-account-request"
  control_tower_parameters = {
    AccountEmail              = "customer_0101@josh.com"
    AccountName               = "Josh" # AWS Account name must be unique
    ManagedOrganizationalUnit = "Workload-Prod"
    SSOUserEmail              = "joshy@josh.com"
    SSOUserFirstName          = "JOSH"
    SSOUserLastName           = "YEFAH"  
  }
  account_tags = {
   "CustomerName" = "josh"
   "AccountType"  = "production"
   "Owner"        = "CloudOps"
  }
  change_management_parameters = {
   change_requested_by = "JOSH Y."
   change_reason       = "Created new production enviroment"
  }
  custom_fields = {
    customer_id                 = "01"
    customer_name               = "josh"
    private_domain              = "joshfis.com"
    public_domain               = "josh.com"
    account_name                = "customer-josh-production" #AzureAD Group prefix must be unique
    account_type                = "production"
    enviroment_name             = "production" # Deprecated
    main_region                 = "us-east-1"
    vpc_internal_id             = "101"
    enviroment_owner            = "CloudOps"
    terragrunt                  = "true"
    migration                   = "false"
    import_kms_cmk_id           = "" # Optional (can be added after account is created)
  }
  account_customizations_name = "customer-josh-production"
}
