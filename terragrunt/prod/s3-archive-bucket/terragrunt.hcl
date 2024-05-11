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
  add_archive_record = true
  ## Set true whether you want to create notification queue
  create_notification_queue = false
  ## Set desired archive id
  archive_id = 10 # should increment in each bucket
  ## Set desired default retention days
  bucket_default_retention_days = 100
  ## Set desired bucket lifecycle days
  bucket_lifecycle_days = 101
  ## Set bucket retention mode (GOVERNANCE | COMPLIANCE)
  bucket_default_retention_mode = "COMPLIANCE"
}

include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/s3-archive.hcl"
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
        "Resource": "$${bucket_arn}/*",
        "Condition": {
          "StringNotEquals": {
            "aws:SourceVpce": "$${s3_endpoint_id}"
          }
        }
      }
    ]
  }
  EOF
  lifecycle_rule = [
    {
      id                                     = "delete-after-${local.bucket_lifecycle_days}-days"
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
