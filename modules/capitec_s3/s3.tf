# S3 bucket for Terraform remote state - one per environment.
# Used by bootstrap/state-buckets (see README "Remote state").

# Prefix follows the format <surname><first_initial>
variable "prefix" {
  type        = string
  description = "distinguishing prefix for resource arguments which identifies the owner <surname><first_initial>"
  default     = "adonisn"
}

variable "environment" {
  type        = string
  description = "Name of the environment"
}

variable "enable_versioning" {
  type        = bool
  description = "Whether to enable versioning for the S3 bucket"
}

# Bucket name follows the format <prefix>-s3-<environment_name>, e.g. adonisn-s3-dev
locals {
  bucket_name = "${var.prefix}-s3-${var.environment}"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket        = local.bucket_name
  force_destroy = true # lets terraform destroy empty out old state versions
}

# Versioning keeps old copies of the state file so a bad apply can be rolled back
resource "aws_s3_bucket_versioning" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# State files can hold sensitive values - never public
resource "aws_s3_bucket_public_access_block" "my_bucket" {
  bucket                  = aws_s3_bucket.my_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  description = "Name of the state bucket"
  value       = aws_s3_bucket.my_bucket.bucket
}
