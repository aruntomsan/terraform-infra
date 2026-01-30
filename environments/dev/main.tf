# 1. Network Module
module "vpc" {
  source      = "../../modules/vpc"
  environment = var.environment    
  vpc_cidr    = var.vpc_cidr          
}

# 2. ECR Module
module "ecr" {
  source      = "../../modules/ecr"
  for_each = toset(var.repos)
  environment = var.environment      
  repo_name   = each.value 
}

# 3. EKS Module
module "eks" {
  source       = "../../modules/eks"
  environment  = var.environment      
  cluster_name = var.eks_cluster_name 
  
  # Dependency injection 
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
  depends_on = [module.vpc]
  dependency_confirmed = module.vpc.dependency_confirmed
}

# 4. Addons (Helm Charts)
module "addons" {
  source = "../../modules/addons"
  depends_on = [module.eks]
}