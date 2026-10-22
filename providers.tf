terraform {
  required_version = ">= 1.10" # needed for use_lockfile (S3 state locking)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state - settings come from envs/<env>/<env>.tfbackend at init time:
  # terraform init -backend-config=envs/dev/dev.tfbackend
  backend "s3" {}
}

provider "aws" {
  region = "af-south-1"

  # Tags added to EVERY resource this provider creates (incl. resources inside modules)
  default_tags {
    tags = local.common_tags
  }
}
