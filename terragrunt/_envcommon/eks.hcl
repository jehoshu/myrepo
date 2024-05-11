terraform {
  source = "tfr://app.terraform.io/josh/eks/aws//?version=${local.tf_versions["aws-eks"]}"

}

locals {
  # Automatically load environment-level variables
  tf_versions                  = yamldecode(file(find_in_parent_folders("tf-versions.yaml")))
  environment_vars             = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                          = local.environment_vars.locals.environment
  main_nodegroup_instance_type = local.environment_vars.locals.main_nodegroup_instance_type
  ha_nodegroup_instance_type   = local.environment_vars.locals.ha_nodegroup_instance_type
  aws_region                   = local.environment_vars.locals.aws_region

}

inputs = {
  cluster_version               = "1.25"
  environment                   = local.env
  ebs_encryption_enabled        = false
  eks_security_group_id         = dependency.security-groups-set.outputs.eks-cluster-security-group.security_group_id
  eks_control_security_group_id = dependency.security-groups-set.outputs.eks-control-security-group.security_group_id
  private_subnets               = dependency.parameters.outputs.private_subnets
  private_tagged_subnets        = dependency.aws_vpc_tagging.outputs.private_tagged_subnets
  vpc_id                        = dependency.parameters.outputs.vpc_id
  kms_key_id                    = dependency.parameters.outputs.key_alias_arn
  customer_name                 = dependency.parameters.outputs.customer_name
  main_nodegroup_instance_type  = local.main_nodegroup_instance_type
  istio_internal_elb            = dependency.security-groups-set.outputs.istio-internal-elb-security-group.security_group_id
  internet_facing_elb           = dependency.security-groups-set.outputs.internet-facing-elb-security-group.security_group_id
  ha_nodegroup_instance_types   = [local.ha_nodegroup_instance_type]
  ha_subnet_ids                 = setsubtract(dependency.parameters.outputs.private_subnets, dependency.aws_vpc_tagging.outputs.private_tagged_subnets)
  ha_nodegroup_desired_size     = 1
  ha_nodegroup_min_size         = 1
  ha_nodegroup_max_size         = 1
  main_nodegroup_desired_size   = 4
  main_nodegroup_min_size       = 4
  main_nodegroup_max_size       = 4
}

dependency "aws_vpc_tagging" {
  config_path = "../aws-vpc-tagging"
  mock_outputs = {
    private_tagged_subnets = ["temporary-dummy"]
  }
}

dependency "parameters" {
  config_path = "../parameters"
  mock_outputs = {
    environment_name              = "temporary-dummy-id"
    eks_security_group_id         = "temporary-dummy-id"
    eks_control_security_group_id = "temporary-dummy-id"
    private_subnets               = "temporary-dummy-id"
    vpc_id                        = "temporary-dummy-id"
    key_alias_arn                 = "temporary-dummy-id"
    customer_name                 = "dummy"
    internet_facing_elb           = "dummy"
    istio_internal_elb            = "dummy"
  }
}

dependency "security-groups-set" {
  config_path  = "../security-groups-set"
  skip_outputs = false
}

dependencies {
  paths = ["../parameters", "../aws-vpc-tagging", "../security-groups-set"]
}
