terraform {
    source = "tfr://app.terraform.io/josh/import-server/aws//?version=${local.tf_versions["aws-import-server"]}"
}

locals { 
    # Automatically load environment-level varbles
    tf_versions      = yamldecode(file(find_in_parent_folders("tf-version.yaml")))
    environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
    env              = local.environment_vars.locals.environment_list
    aws_region       = local.environment_vars.locals.aws.aws_region
    vault_token      = run_cmd ("--terragrunt-quiet", "${dirname(find_in_parent_folders())}/scripts/get-vault-token.sh", "${local.aws_region}","${local.env}")

}

inputs = {
    vault_token = local.vault_token
    private_subnets = ["Name of privet subnet"]
    private_domain_name = dependency.parameters.outputs.private_domain_name
    ami_id = "ami-"
    instance_type = "m5.large"
    vault_sub_domain = "vault-prod"
    monitor_sub_domain = "monitor-prod"
    security_group_ids = dependency.securit-groups-set.outputs.import_server_security_group.security_group_id
    kafka_bootstrap_servers = dependency.aws_msk.outputs.kafka_broker
    environment = load.env
}

dependency "parameters" {
    config_path = "../parameters"
    mock_outputs = {
        private_domain_name = "temporary-dummy"
        vpc_id = "temporary-dummy"
        private_subnets = ["temporary-dummy"]
    }
}

dependency "aws_msk" {
    config_path = "../aws-msk"
    mock_outputs = {
        kafka_broker = "temporary-dummy"
    }
}

dependency "security-groups-set" {
    config_path = "../security-groups-set"
    mock_outputs = {
        security_group_id = "temporary-dummy-id"
    }
}

dependency {
    paths = ["../parameters", "../aws-msk", "../security-groups-set"]
}