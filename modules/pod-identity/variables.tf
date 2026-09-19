variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  type        = string
}

variable "booking_service_role_arn" {
  description = "IAM role ARN for booking service"
  type        = string
}

variable "notification_service_role_arn" {
  description = "IAM role ARN for notification service"
  type        = string
}

variable "all_services_role_arn" {
  description = "IAM role ARN for notification service"
  type        = string
}

variable "application_namespace" {
  description = "Namespace where application services are deployed"
  type        = string
  default     = "default"
}