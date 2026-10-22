# Resource names follow <surname>-<initial>-<resource>-<environment>, e.g. adonis-n-eks-dev
locals {
  prefix = "${var.surname}-${var.initial}"

  cluster_name      = "${local.prefix}-eks-${var.environment}"
  cluster_role_name = "${local.prefix}-eks-cluster-role-${var.environment}"
  node_role_name    = "${local.prefix}-eks-node-role-${var.environment}"
  node_group_name   = "${local.prefix}-eks-nodes-${var.environment}"
  subnet_name       = "${local.prefix}-eks-subnet-${var.environment}"

  # Tags added to every resource in this module (works even when run from this folder)
  common_tags = {
    APP         = "capitec-terraform-training"
    OWNER       = "Geeks4Learning"
    AUTHOR      = "Niyaaz Adonis"
    ENVIRONMENT = var.environment
    MANAGED_BY  = "terraform"
  }
}
