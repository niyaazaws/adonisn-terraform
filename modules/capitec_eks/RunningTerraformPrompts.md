# Running Terraform with prompts (EKS module)

## Values to enter

var.environment        = dev
var.initial            = n
var.instance_type      = t3.medium
var.nodeport_from_port = 30007
var.nodeport_to_port   = 30007
var.surname            = adonis

## Defaults (not prompted)

subnet_cidrs           = {"af-south-1a"="172.31.160.0/24","af-south-1b"="172.31.161.0/24","af-south-1c"="172.31.162.0/24"}
kubernetes_version     = 1.37
capacity_type          = ON_DEMAND
node_min_size          = 1
node_max_size          = 3
node_desired_size      = 1
nodeport_allowed_cidrs = ["0.0.0.0/0"]
