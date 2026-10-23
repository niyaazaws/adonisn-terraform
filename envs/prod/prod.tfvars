environment = "prod"
surname     = "adonis"
initial     = "n"

# EKS subnets in the default VPC (AZ => CIDR) - unique per environment
subnet_cidrs = {
  "af-south-1a" = "172.31.180.0/24"
  "af-south-1b" = "172.31.181.0/24"
  "af-south-1c" = "172.31.182.0/24"
}

# Worker nodes (EC2)
instance_type     = "t3.large" # more CPU/memory for real workloads
capacity_type     = "ON_DEMAND"
node_min_size     = 1
node_max_size     = 3
node_desired_size = 1

# NodePort for the nginx service
nodeport_from_port     = 30007
nodeport_to_port       = 30007
nodeport_allowed_cidrs = ["0.0.0.0/0"]
