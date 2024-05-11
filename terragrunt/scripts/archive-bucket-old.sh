#!/bin/bash
# lap() {
#  local aws_profile=$1
#  aws sso login --profile ${aws_profile}
#  export AWS_PROFILE=${aws_profile}
# }
# lap $1
# account_nmr=$(aws --profile $1 sts get-caller-identity | jq .Account | sed "s/\"//g")


# Function to create folder
create_folder() {
    # Get folder name from user input
    read -p "Enter the folder name: " folder_name

    # Create folder
    if [ ! -d "$folder_name" ]; then
        mkdir "$folder_name"
        echo "Folder '$folder_name' created successfully!"
    else
        echo "Folder '$folder_name' already exists!"
    fi
}

# Function to create Terragrunt file
create_terragrunt_file() {
    # Get configurable parameters from user input
    read -p "Enter the value for add_archive_record (true/false): " add_archive_record
    read -p "Enter the value for create_notification_queue (true/false): " create_notification_queue
    read -p "Enter the value for archive_id: " archive_id
    read -p "Enter the value for bucket_default_retention_days: " bucket_default_retention_days
    read -p "Enter the value for bucket_lifecycle_days: " bucket_lifecycle_days
    read -p "Enter the value for bucket_default_retention_mode (GOVERNANCE/COMPLIANCE): " bucket_default_retention_mode

    # Get folder name from user input
    read -p "Enter the folder name where Terragrunt file will be created: " folder_name

    # Create Terragrunt file inside the folder
    cat << EOF > "$folder_name/terragrunt.hcl"
# AWS S3 ARCHIVE BUCKET
locals {
  # NON-ADJUSTABLE VARIABLES
  parsed_path      = basename(get_terragrunt_dir())
  bucket_name      = local.parsed_path
  archive_name     = local.parsed_path
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment

  # BUCKET CUSTOMIZATIONS (ADJUSTABLE)
  ## Set true whether to add a archive record to server_info table
  add_archive_record = $add_archive_record
  ## Set true whether you want to create notification queue
  create_notification_queue = $create_notification_queue
  ## Set desired archive id
  archive_id = $archive_id # should increment in each bucket
  ## Set desired default retention days
  bucket_default_retention_days = $bucket_default_retention_days
  ## Set desired bucket lifecycle days
  bucket_lifecycle_days = $bucket_lifecycle_days
  ## Set bucket retention mode (GOVERNANCE | COMPLIANCE)
  bucket_default_retention_mode = "$bucket_default_retention_mode"
}

include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "\${dirname(find_in_parent_folders())}/_envcommon/s3-archive.hcl"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# Ovride common inputs if needed here
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  # NON-ADJUSTABLE INPUTS (DO NOT CHANGE)
  add_archive_record        = local.add_archive_record
  create_notification_queue = local.create_notification_queue
  archive_id                = local.archive_id
  bucket_name               = local.bucket_name
  archive_name              = local.archive_name
  bucket_default_retention_mode = local.bucket_default_retention_mode
  bucket_default_retention  = local.bucket_default_retention_days
  bucket_policy             = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "VPCe",
    "Statement": [
      {
        "Sid": "VPCe",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "*",
        "Resource": "\$\${bucket_arn}/*",
        "Condition": {
          "StringNotEquals": {
            "aws:SourceVpce": "\$\${s3_endpoint_id}"
          }
        }
      }
    ]
  }
  EOF
  lifecycle_rule = [
    {
      id                                     = "delete-after-\${local.bucket_lifecycle_days}-days"
      abort_incomplete_multipart_upload_days = local.bucket_lifecycle_days
      enabled                                = true
      expiration = [
        {
          days                         = local.bucket_lifecycle_days
          expired_object_delete_marker = false
        }
      ]
      noncurrent_version_expiration = [
        {
          days = local.bucket_lifecycle_days
        }
      ]
    }
  ]
}
EOF

    echo "Terragrunt file 'terragrunt.hcl' created successfully in folder '$folder_name'!"
}

# Function to create folder and Terragrunt file
create_folder_and_terragrunt_file() {
    create_folder
    create_terragrunt_file
}

# Call the function to create folder and Terragrunt file
create_folder_and_terragrunt_file
