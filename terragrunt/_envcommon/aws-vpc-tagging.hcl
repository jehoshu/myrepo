terraform {
  source = "tfr://app.terraform.io/josh/vpc-tagging/aws//?version=${local.tf_versions["aws-vpc-tagging"]}"
}

locals {
  # Automatically load environment-level variables
  tf_versions      = yamldecode(file(find_in_parent_folders("tf-versions.yaml")))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  env                  = local.environment_vars.locals.environment
  customer_name        = local.environment_vars.locals.customer_name
  aws_region           = local.environment_vars.locals.aws_region
  extended_subnets_use = local.environment_vars.locals.extended_subnets_use
}

inputs = {
  account_type  = dependency.parameters.outputs.account_type
  environment   = local.env
  customer_name = local.customer_name
  aws_region    = local.aws_region
  main_az       = "a"
  # secondary_az                  = "b"
  # third_az                      = "c"
  extended_subnets = local.extended_subnets_use
}

dependency "parameters" {
  config_path = "../parameters"
  mock_outputs = {
    environment_name = "temporary-dummy-id"
    account_type     = "temporary-dummy"
  }
}

dependencies {
  paths = ["../parameters"]
}
