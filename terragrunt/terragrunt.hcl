## Auto generated terragrunt.hcl ##
## Updated on:  ##

# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  env             = local.environment_vars.locals.environment
  customer_name   = local.environment_vars.locals.customer_name
  customer_id     = local.environment_vars.locals.customer_id
  vpc_internal_id = local.environment_vars.locals.vpc_internal_id
  environment_owner = local.environment_vars.locals.environment_owner
  # Extract the variables we need for easy access
  aws_region = local.environment_vars.locals.aws_region

}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  allowed_account_ids = ["533146082706"]
  default_tags {
    tags = {
      managed_by                  = "${local.environment_owner}"
      customer_name               = "${local.customer_name}"
      customer_id                 = "${local.customer_id}"
      environment                 = "${local.env}"
      vpc_internal_id             = "${local.vpc_internal_id}"
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    region         = "${local.aws_region}"
    bucket         = "123-terrafrom-state-b965a90ff10e"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    dynamodb_table = "terraform-locks"
    kms_key_id     = "123a3842-8aad-4881-a974-e9f4a4f20372"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "4.57.0"
        }
      }
    }
EOF
}
