variable "environment" {}
variable "cluster_name" {}
variable "vpc_id" {}
variable "dependency_confirmed" {}
variable "subnet_ids" {
  type = list(string)
}

# 1. EKS Module (Creates Cluster & OIDC)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.15.0"

  name    = "${var.environment}-${var.cluster_name}"
  kubernetes_version = "1.35"

  endpoint_public_access = true
  enable_irsa = true
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  addons = {
    vpc-cni = {
      before_compute = true
    }
    kube-proxy = {}
    coredns    = {}
    eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    general = {
      min_size     = 2
      max_size     = 10
      desired_size = 4
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }

  enable_cluster_creator_admin_permissions = true
  tags = {
    dependency_confirmed = var.dependency_confirmed
  }
}

# 2. IAM Role Module (Depends on EKS OIDC)
module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name             = "ebs-csi-driver-role"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# 3. EBS CSI Addon Resource (Depends on EKS & IAM)
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.ebs_csi_irsa_role.arn
  depends_on = [
    module.ebs_csi_irsa_role,
    module.eks
  ]
}