This article explains how to use the AFT pipeline to create AWS account using the pipeline and pick customization to it.

Instructions 
In account request repository:
1. Create a new branch to initialize account request out of the main branch
2. Create a copy of file account.tf files
3. Rename account.tf files that you choose
4. Fill out of the fields in control_tower_parapeters
    AccountEmail              = "customer_0101@demo.com"
    AccountName               = "Demo-account" # AWS Account name must be unique
    ManagedOrganizationalUnit = "Workload-dev"
    SSOUserEmail              = "Iam@josh.com"
    SSOUserFirstName          = "Iam"
    SSOUserLastName           = "Iam"
5. Fill up the fields in account_tags
   "CustomerName" = "Josh"
   "Environment"  = "demo"
   "Owner"        = "DevOps"
6. Fill up the fields in change_management_parameters
   change_requested_by = "Iam"
   change_reason       = "Created new demo account"
7. Fill the fields in custom_fields
    customer_id                 = "00"
    customer_name               = "josh"
    private_domain              = "joshfis.com"
    public_domain               = "josh.com"
    account_name                = "customer-josh-production"
    account_type                = "demo"
    enviroment_name             = "dev" 
    main_region                 = "us-east-1"
    vpc_internal_id             = "10"
    enviroment_owner            = "CloudOps"
    terragrunt                  = "true"
   
