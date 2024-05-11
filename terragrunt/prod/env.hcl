locals {
  environment = "production"
  aws_region = "us-east-1"
  bucket_name = "123-terrafrom-state-c8681bad4c17"
  bucket_kms_key_id = "12369d28-06b4-4056-aef6-59b67d04ad4d"
  vended_account_custom_fields = jsondecode("{\"account_name\":\"test-fis\",\"customer_id\":\"32\",\"customer_name\":\"test-fis\",\"environment_name\":\"prod\",\"environment_owner\":\"CloudOps\",\"main_region\":\"us-east-1\",\"private_domain\":\"josh.com\",\"public_domain\":\"josh.com\",\"terragrunt\":\"true\",\"vpc_internal_id\":\"123\"}")
  customer_id = local.vended_account_custom_fields.customer_id
  customer_name = local.vended_account_custom_fields.customer_name
  private_domain = local.vended_account_custom_fields.private_domain
  account_name = local.vended_account_custom_fields.account_name
  public_domain = local.vended_account_custom_fields.public_domain
  vpc_internal_id = local.vended_account_custom_fields.vpc_internal_id
  rds_instance_type = "db.m5.xlarge"
  es_instance_type = "i3.2xlarge.elasticsearch"
  main_nodegroup_instance_type = "m5.2xlarge"
  sub_environment_list = []
  image_registry = "123404668857.dkr.ecr.eu-west-1.amazonaws.com"
  envs_list = concat(local.sub_environment_list, [local.environment, local.active_environment], local.tuning_environment ? ["tuning"] : [])
  environments_list = [for env in local.envs_list : "${env}"]
  tuning_environment = true
  extended_subnets_use = true
  environment_owner = local.vended_account_custom_fields.environment_owner
  ha_nodegroup_instance_type = "t3.xlarge"
  additional_datasources_buckets = []
  release_color = "green"
  active_environment = join("-", [local.environment, local.release_color])
  monitoring = {
    loki_enabled         = true
    grafana_enabled      = true
    remote_write_enabled = true
    region               = local.aws_region
    }
}
