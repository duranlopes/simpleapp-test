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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access             = true
  authentication_mode                = "CONFIG_MAP"
  create_primary_security_group_tags = var.create_primary_security_group_tags

  enable_cluster_creator_admin_permissions = false
  create_kms_key                           = var.create_kms_key
  encryption_config                        = var.create_kms_key ? {} : null
  enabled_log_types                        = var.enabled_log_types

  eks_managed_node_groups = {
    default = {
      name                     = "${var.cluster_name}-node-group"
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-node-role"
      iam_role_use_name_prefix = false
      instance_types           = [var.node_instance_type]

      # Let EKS select its managed-node AMI; this avoids an SSM lookup and
      # keeps the same module graph compatible with the Floci API emulator.
      create_launch_template         = false
      use_custom_launch_template     = false
      use_latest_ami_release_version = false

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size
    }
  }

  tags = {
    Environment = "development"
    Terraform   = "true"
  }
}
