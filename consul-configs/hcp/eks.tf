data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.22.0"

  cluster_name    = "${var.cluster_id}-eks"
  cluster_version = "1.21"
  subnets         = module.eks-vpc.public_subnets
  vpc_id          = module.eks-vpc.vpc_id

  node_groups = {
    nodes = {
      name_prefix      = "eks-cluster"
      instance_types   = ["m5.large"]
      desired_capacity = 3
      max_capacity     = 3
      min_capacity     = 3
    }
  }
}