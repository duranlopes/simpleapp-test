module "network" {
  source = "../modules/floci-network"

  cluster_name = var.cluster_name
  region       = var.region
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = "arn:aws:iam::000000000000:role/floci-eks-role"
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids         = module.network.subnet_ids
    security_group_ids = [module.network.security_group_id]
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = "arn:aws:iam::000000000000:role/floci-eks-node-role"
  subnet_ids      = module.network.subnet_ids

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  depends_on = [aws_eks_cluster.this]
}

output "cluster_name" {
  description = "Floci EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_status" {
  description = "Floci EKS cluster status."
  value       = aws_eks_cluster.this.status
}

output "node_group_status" {
  description = "Floci EKS node group status."
  value       = aws_eks_node_group.this.status
}
