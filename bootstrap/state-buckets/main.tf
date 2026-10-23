####################################################################
# One-time bootstrap: the S3 buckets that hold the remote state
#
# Apply this manually, once, before the main project:
#   cd bootstrap/state-buckets
#   terraform init
#   terraform apply
#
# This uses LOCAL state on purpose - the main project's backend
# can't store its state in a bucket that doesn't exist yet.
####################################################################

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "af-south-1"

  default_tags {
    tags = {
      APP        = "capitec-terraform-training"
      OWNER      = "Geeks4Learning"
      AUTHOR     = "Niyaaz Adonis"
      MANAGED_BY = "terraform"
      PURPOSE    = "terraform-state"
    }
  }
}

# Environment => versioning. dev is throwaway; qa and prod keep state history.
variable "environments" {
  type        = map(bool)
  description = "Environments to create a state bucket for, and whether versioning is on"
  default = {
    dev  = false
    qa   = true
    prod = true
  }
}

# One bucket per environment, so dev/qa/prod state never share a bucket
module "state_bucket" {
  source   = "../../modules/capitec_s3"
  for_each = var.environments

  prefix            = "adonisn"
  environment       = each.key
  enable_versioning = each.value
}

output "state_buckets" {
  description = "Bucket per environment - must match envs/<env>/<env>.tfbackend"
  value       = { for env, bucket in module.state_bucket : env => bucket.bucket_name }
}
