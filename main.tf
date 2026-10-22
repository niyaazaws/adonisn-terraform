module "eks" {
  source             = "./modules/capitec_eks"
  surname            = var.surname
  initial            = var.initial
  environment        = var.environment
  kubernetes_version = var.kubernetes_version
  subnet_cidrs       = var.subnet_cidrs

  # Worker nodes (EC2)
  instance_type     = var.instance_type
  capacity_type     = var.capacity_type
  node_min_size     = var.node_min_size
  node_max_size     = var.node_max_size
  node_desired_size = var.node_desired_size

  # NodePort access
  nodeport_from_port     = var.nodeport_from_port
  nodeport_to_port       = var.nodeport_to_port
  nodeport_allowed_cidrs = var.nodeport_allowed_cidrs
}
