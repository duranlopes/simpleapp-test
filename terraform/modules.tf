module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

module "master" {
  source = "./modules/master"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  private_subnet_1a = module.vpc.private_subnets[0]
  private_subnet_1b = module.vpc.private_subnets[1]
}

module "node" {
  source = "./modules/node"

  cluster_name = module.master.cluster_name

  private_subnet_1a = module.vpc.private_subnets[0]
  private_subnet_1b = module.vpc.private_subnets[1]

  desired_size = var.desired_size
  min_size     = var.min_size
  max_size     = var.max_size
}
