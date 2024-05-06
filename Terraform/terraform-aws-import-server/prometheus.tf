terraform {
  source = "tfr://app.terraform.io/josh/prometheus-operator/k8s//?version=${local.tf_versions["k8s-prometheus-operator"]}"
}

locals {
  # Automatically load environment-level variables
  release_color    = local.environment_vars.locals.release_color
  tf_versions      = yamldecode(file(find_in_parent_folders("tf-versions.yaml")))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  aws_region       = local.environment_vars.locals.aws_region

}

inputs = {
  amp_workspace_id                 = "ab-206c9fb1-d73f-4649-aabe-1fa473b8fcb2"
  management_account_id            = "123404668857"
  region                           = "eu-west-1"
  environment                      = join("-", [local.env, local.release_color])
  customer_name                    = dependency.parameters.outputs.customer_name
  cluster_name                     = dependency.eks.outputs.aws_eks_cluster_id
  cluster_identity_oidc_issuer     = dependency.eks.outputs.aws_eks_cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = dependency.eks.outputs.aws_eks_oidc_provider_arn
  customer_id                      = local.environment_vars.locals.customer_id
  loki_enabled                     = local.environment_vars.locals.monitoring.loki_enabled
  grafana_enabled                  = local.environment_vars.locals.monitoring.grafana_enabled
  remote_write                     = local.environment_vars.locals.monitoring.remote_write_enabled
  region                           = local.environment_vars.locals.monitoring.region 
}

dependency "parameters" {
  config_path = "../../global/parameters"
  mock_outputs = {
    private_domain_name = "temporary-dummy"
    environment_name    = "temporary-dummy"
  }
}

dependency "eks" {
  config_path = "../eks"
}

dependencies {
  paths = ["../eks", "../../global/parameters"]
}
