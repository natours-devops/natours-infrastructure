variable "cluster_name" {
  description = "EKS cluster name"
}

variable "sqs_queue_arn" {
  description = "Main SQS queue ARN for booking events"
}

variable "sqs_dlq_arn" {
  description = "Dead letter queue ARN"
}

variable "cluster_depends_on" {
  description = "Pass EKS cluster resource to create dependency"
  type        = any
  default     = null
}

variable "aws_region" {
  type = string
}