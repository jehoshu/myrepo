terraform {
  source = "tfr://app.terraform.io/josh/prometheus-exporters/k8s//?version=${local.tf_versions["k8s-prometheus-exporters"]}"
}

locals {
  tf_versions      = yamldecode(file(find_in_parent_folders("tf-versions.yaml")))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  aws_region       = local.environment_vars.locals.aws_region
  vault_token      = run_cmd ("--terragrunt-quiet", "${dirname(find_in_parent_folders())}/scripts/get-vault-token.sh", "${local.aws_region}","${local.env}")
}

inputs = {
  environment                      = local.env
  customer_name                    = dependency.parameters.outputs.customer_name
  eks_cluster_name                 = dependency.eks.outputs.aws_eks_cluster_id
  cluster_identity_oidc_issuer     = dependency.eks.outputs.aws_eks_cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = dependency.eks.outputs.aws_eks_oidc_provider_arn
  private_domain_name              = dependency.parameters.outputs.private_domain_name
  es_domain_name                   = local.env
  vault_token                      = local.vault_token
  vault_secret_path                = "kvv2/cred/${local.env}"
  vault_url                        = "vault-${local.env}"
}

dependency "parameters" {
  config_path = "../../global/parameters"
  mock_outputs = {
    private_domain_name = "temporary-dummy"
    environment   = "temporary-dummy"
    customer_name = "temporary-dummy"
  }
}
 
dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    aws_eks_cluster_id = "temporary-dummy"
    aws_eks_cluster_oidc_issuer_url   = "temporary-dummy"
    aws_eks_oidc_provider_arn = "temporary-dummy"
  }
}

dependencies {
  paths = ["../eks", "../../global/parameters", "../vault"]
}
