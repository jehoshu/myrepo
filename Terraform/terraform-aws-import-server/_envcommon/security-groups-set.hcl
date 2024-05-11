terraform {
  source = "tfr://app.terraform.io/josh/security-groups-set/aws//?version=${local.tf_versions["aws-security-groups-set"]}"
}

locals {
  # Automatically load environment-level variables
  release_color    = local.environment_vars.locals.release_color
  tf_versions      = yamldecode(file(find_in_parent_folders("tf-versions.yaml")))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  customer_name    = local.environment_vars.locals.customer_name
  customer_id      = local.environment_vars.locals.customer_id
}

inputs = {
  customer_name         = local.customer_name
  environment_name      = local.env
  vpc_id                = dependency.parameters.outputs.vpc_id
  vpn_vpc_cidr          = ["10.115.0.0/16"]
  create_ssm_parameters = false
  customer_cidr_list = [
    # customer ip adress
    "",
    "",
    # fortinet ip 
    ""
  ]
}

dependency "parameters" {
  config_path = "../parameters"
  mock_outputs = {
    vpc_id = "temporary-dummy-id"

  }
}

dependencies {
  paths = ["../parameters"]
}
