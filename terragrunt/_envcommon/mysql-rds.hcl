terraform {
  source = "tfr://app.terraform.io/josh/mysql-rds/aws//?version=${local.tf_versions["aws-mysql-rds"]}"

}

locals {
  # Automatically load environment-level variables
  tf_versions       = yamldecode(file(find_in_parent_folders("tf-versions.yaml")))
  environment_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env               = local.environment_vars.locals.environment
  rds_instance_type = local.environment_vars.locals.rds_instance_type
  aws_region        = local.environment_vars.locals.aws_region
  vault_token       = run_cmd("--terragrunt-quiet", "${dirname(find_in_parent_folders())}/scripts/get-vault-token.sh", "${local.aws_region}", "${local.env}")
}

inputs = {
  aws_eks_cluster_id     = dependency.eks.outputs.aws_eks_cluster_id
  vault_token            = local.vault_token
  environment_name       = local.env
  hosted_zone_id         = dependency.parameters.outputs.private_hosted_zone_id
  private_domain_name    = dependency.parameters.outputs.private_domain_name
  data_subnets           = dependency.parameters.outputs.database_subnets
  rds_rds_multiaz        = false
  rds_instance_type      = local.rds_instance_type
  rds_security_group_ids = [dependency.security-groups-set.outputs.mysql-security-group.security_group_id]
  rds_kms_key_arn        = dependency.parameters.outputs.key_alias_arn

  rds_instance_static_protection = true
  rds_skip_final_snapshot        = false
  vault_secret_path              = "kvv2/cred/${local.env}/mysql"
  endpoint                       = "mysql-${local.env}"
  vault_url                      = "vault-${local.env}"
}

dependency "parameters" {
  config_path = "../parameters"
  mock_outputs = {
    private_domain_name    = "temporary-dummy"
    database_subnets       = ["temporary-dummy"]
    key_alias_arn          = "temporary-dummy"
    private_hosted_zone_id = "temporary-dummy"
  }
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    aws_eks_cluster_id = "temporary-dummy"
  }
}

dependency "aws_vpc_tagging" {
  config_path = "../aws-vpc-tagging"
  mock_outputs = {
    private_tagged_subnets = ["temporary-dummy"]
  }
}

dependency "security-groups-set" {
  config_path  = "../security-groups-set"
  skip_outputs = false
}

dependencies {
  paths = ["../parameters", "../eks", "../vault", "../security-groups-set", "../aws-vpc-tagging"]
}
