variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "k8s-cluster"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name)) && length(var.cluster_name) <= 100
    error_message = "cluster_name must be 2-100 characters and contain only letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "AWS region where the EKS cluster is provisioned."
  type        = string
  default     = "us-east-1"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane and managed node group."
  type        = string
  default     = "1.33"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must use the MAJOR.MINOR format."
  }
}

variable "desired_size" {
  description = "Desired number of nodes in the managed node group."
  type        = number
  default     = 3

  validation {
    condition     = var.desired_size >= 1
    error_message = "desired_size must be at least 1."
  }
}

variable "min_size" {
  description = "Minimum number of nodes in the managed node group."
  type        = number
  default     = 3

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of nodes in the managed node group."
  type        = number
  default     = 4

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }
}
