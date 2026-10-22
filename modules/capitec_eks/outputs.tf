# Summary of what this module creates - shown at the end of plan/apply
output "summary" {
  description = "Summary of the resources created by the EKS module"
  value = {
    environment = var.environment

    eks_cluster = {
      name    = aws_eks_cluster.eks_cluster.name
      version = aws_eks_cluster.eks_cluster.version
    }

    node_group = {
      name          = aws_eks_node_group.eks_node_group.node_group_name
      instance_type = var.instance_type
      capacity_type = var.capacity_type
      min_size      = var.node_min_size
      max_size      = var.node_max_size
      desired_size  = var.node_desired_size
    }

    subnets = {
      for az, subnet in aws_subnet.eks_subnet : az => subnet.cidr_block
    }

    iam_roles = {
      cluster = aws_iam_role.eks_cluster_role.name
      nodes   = aws_iam_role.eks_node_role.name
    }

    nodeport = {
      from_port     = var.nodeport_from_port
      to_port       = var.nodeport_to_port
      allowed_cidrs = var.nodeport_allowed_cidrs
    }

    admin_access = aws_eks_access_entry.eks_admin.principal_arn
  }
}

# Values only known after apply
output "cluster_endpoint" {
  description = "URL of the EKS Kubernetes API"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_security_group_id" {
  description = "Security group EKS created for the cluster (NodePort rule added here)"
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "subnet_ids" {
  description = "IDs of the EKS subnets, by availability zone"
  value       = { for az, subnet in aws_subnet.eks_subnet : az => subnet.id }
}

output "kubeconfig_command" {
  description = "Command to connect kubectl to the cluster after apply"
  value       = "aws eks update-kubeconfig --region af-south-1 --name ${aws_eks_cluster.eks_cluster.name}"
}
