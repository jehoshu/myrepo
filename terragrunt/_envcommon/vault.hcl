terraform {
  source = "tfr://app.terraform.io/josh/vault/k8s//?version=${local.tf_versions["k8s-vault"]}"

}

locals {
  # Automatically load environment-level variables
  tf_versions      = yamldecode(file(find_in_parent_folders("tf-versions.yaml")))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  aws_region       = local.environment_vars.locals.aws_region

}

inputs = {
  key_alias_arn                   = dependency.parameters.outputs.key_alias_arn
  aws_eks_cluster_oidc_issuer_url = dependency.eks.outputs.aws_eks_cluster_oidc_issuer_url
  aws_eks_oidc_provider_arn       = dependency.eks.outputs.aws_eks_oidc_provider_arn
  aws_eks_cluster_id              = dependency.eks.outputs.aws_eks_cluster_id
  key_alias_arn                   = dependency.parameters.outputs.key_alias_arn
  private_domain_name             = dependency.parameters.outputs.private_domain_name
  environment                     = local.env
}

dependency "parameters" {
  config_path = "../parameters"
  mock_outputs = {
    key_alias_arn       = "temporary-dummy-id"
    private_domain_name = "temporary-dummy-id"
  }
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    aws_eks_cluster_oidc_issuer_url = "temporary-dummy-id"
    aws_eks_oidc_provider_arn       = "temporary-dummy-id"
    aws_eks_cluster_id              = "temporary-dummy-id"
  }
}

dependencies {
  paths = ["../parameters","../eks"]
}
