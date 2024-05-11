#!/bin/sh
export ENV_NAME=$(aws ssm get-parameter --region $1 --name "/aft/account_custom_fields/environment_name" --query "Parameter.Value" --output text | jq --raw-output)
export TG_TF_REGISTRY_TOKEN=$(aws ssm get-parameter --region $1 --name /aft/$ENV_NAME/terraform/registry/token  --query "Parameter.Value" --output text --with-decrypt)
export TF_TOKEN_app_terraform_io=$TG_TF_REGISTRY_TOKEN