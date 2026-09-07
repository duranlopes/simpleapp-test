variable "cluster_name" {
  description = "Name of the Floci EKS test cluster."
  type        = string
  default     = "simpleapp-floci"
}

variable "region" {
  description = "AWS region used by the Floci API."
  type        = string
  default     = "us-east-1"
}

variable "kubernetes_version" {
  description = "Kubernetes version reported by the Floci EKS API."
  type        = string
  default     = "1.33"
}

variable "node_group_name" {
  description = "Name of the Floci EKS node group."
  type        = string
  default     = "simpleapp-floci-nodes"
}
