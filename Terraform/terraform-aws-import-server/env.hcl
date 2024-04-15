locals {vi
    environment = "prod"
    aws_region = "us-east-1"
    bucket_name = "111-terrafrom-state-12b3456bf" EXAMPLE
    bucket_kms_key_id = "23123dfs-12ds-3345-67d3454577" EXAMPLE
    vended_account_custom_fields = jsoncode("{\"account_name\":\"customer-josh\",\"account_type\:\"prod\",\"customer_id\:\"81\"}")
    account_name = local.vended_account_custom_fields.account_name
    customer_id = local.vended_account_custom_fields.customer_id
    rds_instance_id = "db.t3.large"
    es_instance_type = "i3.xlarge.elasticsearch"
    main_nodegroup_instance_type = "m5.2xlarge"
    ha_nodegroup_instance_type = "m5.2xlarge"
    sub_environment_list = []
    image_registry = "123456789012.dkr.ecr.eu-west-1.amazonaws.com"
    envs_list = concat (local.sub_environment_list, [local.environment, local.active_environment])
    environment_list =[for env in local.envs_list : "${env}"]
    extended_subnets_use = false
}