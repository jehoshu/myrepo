terraform {
  source = "tfr://app.terraform.io/shieldfc/s3-archive/aws//?version=${local.tf_versions["aws-s3-archive"]}"
}

locals {
  # Automatically load environment-level variables
  tf_versions      = yamldecode(file(find_in_parent_folders("tf-versions.yaml")))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  aws_region       = local.environment_vars.locals.aws_region
  customer_name    = local.environment_vars.locals.customer_name
  customer_id      = local.environment_vars.locals.customer_id
  vault_token      = run_cmd("--terragrunt-quiet", "${dirname(find_in_parent_folders())}/scripts/get-vault-token.sh", "${local.aws_region}", "${local.env}")

}

inputs = {
  create_vault_secret      = true
  vault_token              = local.vault_token
  environments_list        = local.environment_vars.locals.environments_list
  customer_name            = local.customer_name
  customer_id              = local.customer_id
  environment              = local.env
  archive_hostname         = "aws-archive.${local.env}.svc" 
  versioning               = true
  bucket_default_retention = 2
  add_archvie_record       = true
  custom_kms_key_arn       = dependency.parameters.outputs.key_alias_arn
  s3_endpoint_id           = dependency.parameters.outputs.s3_aws_vpc_endpoint
  private_domain_name      = dependency.parameters.outputs.private_domain_name
  vault_url                = "vault-${local.env}"
  queue_events             = ["s3:ObjectCreated:*"]
}

dependency "parameters" {
  config_path = "../../parameters"
  mock_outputs = {
    environment_name    = "temporary-dummy"
    private_domain_name = "temporary-dummy"
    key_alias_arn       = "temporary-dummy"
    s3_aws_vpc_endpoint = "temporary-dummy"
  }
}

dependencies {
  paths = ["../../parameters", "../../vault"]
}
