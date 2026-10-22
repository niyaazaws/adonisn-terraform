# Re-export the EKS module outputs so they show when running from the project root
output "eks_summary" {
  description = "Summary of the resources created by the EKS module"
  value       = module.eks.summary
}

output "eks_cluster_endpoint" {
  description = "URL of the EKS Kubernetes API"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group EKS created for the cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_subnet_ids" {
  description = "IDs of the EKS subnets, by availability zone"
  value       = module.eks.subnet_ids
}

output "eks_kubeconfig_command" {
  description = "Command to connect kubectl to the cluster after apply"
  value       = module.eks.kubeconfig_command
}
