variable "create_kms_key" {
  description = "Whether to create a customer-managed KMS key for EKS secrets encryption."
  type        = bool
  default     = true
}

variable "create_primary_security_group_tags" {
  description = "Whether to tag the EKS-managed primary security group."
  type        = bool
  default     = true
}

variable "enabled_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = []
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group."
  type        = string
  default     = "t3.medium"
}
