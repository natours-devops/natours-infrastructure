variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "associations" {
  description = "Map of pod identity associations"
  type = map(object({
    namespace       = string
    service_account = string
    role_arn        = string
  }))
}
