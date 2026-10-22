# Networking - reuse AWS's default VPC (already has an Internet Gateway + main route table to it)
data "aws_vpc" "default_vpc" {
  default = true
}

# One public subnet per AZ in var.subnet_cidrs (new subnets use the VPC's main route table -> IGW)
resource "aws_subnet" "eks_subnet" {
  for_each = var.subnet_cidrs

  vpc_id                  = data.aws_vpc.default_vpc.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true # nodes need a public IP to reach EKS (no NAT gateway)

  tags = merge(local.common_tags, {
    Name                                          = "${local.subnet_name}-${each.key}"
    "kubernetes.io/role/elb"                      = "1"      # lets EKS place public load balancers here
    "kubernetes.io/cluster/${local.cluster_name}" = "shared" # marks the subnet as usable by this cluster
  })
}

# EKS control plane
resource "aws_eks_cluster" "eks_cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version
  tags     = merge(local.common_tags, { Name = local.cluster_name })

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids = [for subnet in aws_subnet.eks_subnet : subnet.id]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

# IAM role the EKS control plane uses to manage AWS resources
resource "aws_iam_role" "eks_cluster_role" {
  name = local.cluster_role_name
  tags = merge(local.common_tags, { Name = local.cluster_role_name })
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# authentication_mode = "API" means Kubernetes RBAC access is governed
# entirely by EKS access entries, not IAM policies or aws-auth. Without
# this, the IAM principal that creates/manages the cluster has no way
# to authenticate to the Kubernetes API.
data "aws_caller_identity" "current" {}

# Gives whoever runs Terraform admin access to the cluster
resource "aws_eks_access_entry" "eks_admin" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
  tags          = local.common_tags
}

resource "aws_eks_access_policy_association" "eks_admin" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_eks_access_entry.eks_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# IAM role the worker node EC2 instances use
resource "aws_iam_role" "eks_node_role" {
  name = local.node_role_name
  tags = merge(local.common_tags, { Name = local.node_role_name })
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_ecr_read_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Opens the nginx NodePort range (from_port - to_port) on the cluster security group
resource "aws_security_group_rule" "nginx_nodeport_ingress" {
  type              = "ingress"
  from_port         = var.nodeport_from_port
  to_port           = var.nodeport_to_port
  protocol          = "tcp"
  cidr_blocks       = var.nodeport_allowed_cidrs
  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  description       = "Allow inbound access to nginx NodePort service"
}

# Worker nodes (EC2) that run the pods
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = local.node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [for subnet in aws_subnet.eks_subnet : subnet.id]
  tags            = merge(local.common_tags, { Name = local.node_group_name })

  capacity_type  = var.capacity_type
  instance_types = [var.instance_type]

  scaling_config {
    min_size     = var.node_min_size
    max_size     = var.node_max_size
    desired_size = var.node_desired_size
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure IAM permissions are created before and deleted after the
  # node group, otherwise EKS cannot properly bootstrap/tear down nodes.
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker_policy,
    aws_iam_role_policy_attachment.eks_node_cni_policy,
    aws_iam_role_policy_attachment.eks_node_ecr_read_policy,
  ]
}
