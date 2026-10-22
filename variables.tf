variable "surname" {
  type        = string
  description = "Owner's surname (lowercase), used as the start of every resource name"
}

variable "initial" {
  type        = string
  description = "Owner's first initial (lowercase), added after the surname, e.g. adonis + n = adonis-n"
}

variable "environment" {
  type        = string
  description = "Environment to deploy: dev, qa or prod"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be dev, qa or prod."
  }
}

variable "enable_versioning" {
  type        = bool
  description = "Whether to enable versioning on the S3 bucket (S3 module)"
  default     = false
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version, e.g. 1.37. Upgrade one minor version at a time"
  default     = "1.37"
}

variable "subnet_cidrs" {
  type        = map(string)
  description = "EKS subnets to create in the default VPC: availability zone => CIDR. Must not overlap other environments/subnets"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the worker nodes, e.g. t3.medium"
}

variable "capacity_type" {
  type        = string
  description = "Worker node pricing: ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
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
}

variable "nodeport_from_port" {
  type        = number
  description = "Start of the NodePort range opened for the nginx service (30000-32767), e.g. 30007"
}

variable "nodeport_to_port" {
  type        = number
  description = "End of the NodePort range (same as from_port for a single port), e.g. 30007"
}

variable "nodeport_allowed_cidrs" {
  type        = list(string)
  description = "IP ranges allowed to reach the NodePort"
  default     = ["0.0.0.0/0"]
}
