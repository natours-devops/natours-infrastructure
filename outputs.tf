# output "private_subnet_ids" {
#   description = "Private subnet IDs passed to the root"
#   value       = module.vpc.private_subnet_ids
# }


output "ecr_repository_urls" {
  description = "All ECR repository URLs"
  value       = module.ecr.repository_urls
}


output "sqs_queue_url" {
  description = "Booking confirmed SQS queue URL"
  value       = module.sqs.queue_url
}

output "sqs_dlq_url" {
  description = "Dead letter queue URL"
  value       = module.sqs.dlq_url
}