# Safety guard - stops a plan/apply when the tfvars environment doesn't match the backend.
# e.g. init with envs/prod/prod.tfbackend, then apply with envs/dev/dev.tfvars => error, nothing changes.
# terraform init saves the backend settings in .terraform/terraform.tfstate, so we read the state key from there.
locals {
  backend_key = try(jsondecode(file("${path.root}/.terraform/terraform.tfstate")).backend.config.key, null)
}

data "aws_caller_identity" "guard" {
  lifecycle {
    precondition {
      condition     = local.backend_key == null || startswith(local.backend_key, "${var.environment}/")
      error_message = "Backend state '${coalesce(local.backend_key, "none")}' does not match environment '${var.environment}'. Run: terraform init -reconfigure -backend-config=envs/${var.environment}/${var.environment}.tfbackend"
    }
  }
}
