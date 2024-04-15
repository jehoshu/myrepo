#!/bin/sh
aws ssm get-parameter --region $1 --name "/aft/$2/vault/root_token" --query "Parameter.Value" --output text --with-decrypt