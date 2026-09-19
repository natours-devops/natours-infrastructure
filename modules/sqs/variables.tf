variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "natours"
}


variable "booking_service_role_arn" {
  description = "IAM role ARN for booking service"
  type        = string
}

variable "notification_service_role_arn" {
  description = "IAM role ARN for notification service"
  type        = string
}