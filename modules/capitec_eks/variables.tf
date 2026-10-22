variable "surname" {
  type        = string
  description = "Owner's surname (lowercase), used as the start of every resource name"

  validation {
    condition     = can(regex("^[a-z]+$", var.surname))
    error_message = "surname must be lowercase letters only."
  }
}

variable "initial" {
  type        = string
  description = "Owner's first initial (one lowercase letter)"

  validation {
    condition     = can(regex("^[a-z]$", var.initial))
    error_message = "initial must be a single lowercase letter."
  }
}

variable "environment" {
  type        = string
  description = "Environment to deploy: dev, qa or prod"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be dev, qa or prod."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version, e.g. 1.37. Upgrade one minor version at a time"
  default     = "1.37"

  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must look like 1.37."
  }
}

variable "subnet_cidrs" {
  type        = map(string)
  description = "EKS subnets to create in the default VPC: availability zone => CIDR. EKS needs at least 2 AZs"
  default = {
    "af-south-1a" = "172.31.160.0/24"
    "af-south-1b" = "172.31.161.0/24"
    "af-south-1c" = "172.31.162.0/24"
  }

  validation {
    condition     = length(var.subnet_cidrs) >= 2
    error_message = "EKS needs subnets in at least 2 availability zones."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the worker nodes, e.g. t3.medium"

  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type must look like t3.medium."
  }
}

variable "capacity_type" {
  type        = string
  description = "Worker node pricing: ON_DEMAND or SPOT"
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 3
}

variable "node_desired_size" {
  type        = number
  description = "Number of worker nodes to run now (must be between min and max)"
  default     = 1

  validation {
    condition     = var.node_desired_size >= var.node_min_size && var.node_desired_size <= var.node_max_size
    error_message = "node_desired_size must be between node_min_size and node_max_size."
  }
}

variable "nodeport_from_port" {
  type        = number
  description = "Start of the NodePort range opened for the nginx service (30000-32767), e.g. 30007"

  validation {
    condition     = var.nodeport_from_port >= 30000 && var.nodeport_from_port <= 32767
    error_message = "nodeport_from_port must be in the NodePort range 30000-32767."
  }
}

variable "nodeport_to_port" {
  type        = number
  description = "End of the NodePort range (same as from_port for a single port), e.g. 30007"

  validation {
    condition     = var.nodeport_to_port >= var.nodeport_from_port && var.nodeport_to_port <= 32767
    error_message = "nodeport_to_port must be >= nodeport_from_port and <= 32767."
  }
}

variable "nodeport_allowed_cidrs" {
  type        = list(string)
  description = "IP ranges allowed to reach the NodePort"
  default     = ["0.0.0.0/0"]
}
