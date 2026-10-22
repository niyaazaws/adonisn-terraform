# Common tags - applied to all resources via default_tags in providers.tf
locals {
  common_tags = {
    APP         = "capitec-terraform-training"
    OWNER       = "Geeks4Learning"
    AUTHOR      = "Niyaaz Adonis"
    ENVIRONMENT = var.environment
    MANAGED_BY  = "terraform"
  }
}
