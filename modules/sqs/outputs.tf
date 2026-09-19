output "queue_url" {
  description = "Main SQS queue URL"
  value       = aws_sqs_queue.booking_confirmed.url
}

output "queue_arn" {
  description = "Main SQS queue ARN"
  value       = aws_sqs_queue.booking_confirmed.arn
}

output "dlq_url" {
  description = "Dead letter queue URL"
  value       = aws_sqs_queue.booking_dlq.url
}

output "dlq_arn" {
  description = "Dead letter queue ARN"
  value       = aws_sqs_queue.booking_dlq.arn
}