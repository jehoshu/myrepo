terraform {
  source = "tfr://app.terraform.io/josh/import-parameters/aws//?version=${local.tf_versions["aws-import-parameters"]}"

}

locals {
  # Automatically load environment-level variables
  release_color        = local.environment_vars.locals.release_color
  tf_versions          = yamldecode(file(find_in_parent_folders("tf-versions.yaml")))
  environment_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                  = local.environment_vars.locals.environment
  aws_region           = local.environment_vars.locals.aws_region
  extended_subnets_use = local.environment_vars.locals.extended_subnets_use
}

inputs = {
  extended_subnets = local.extended_subnets_use
}