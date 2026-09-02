# Dead Letter Queue (DLQ)
# Created first because main queue references it
resource "aws_sqs_queue" "booking_dlq" {
  name                       = "${var.project_name}-booking-confirmed-dlq"
  message_retention_seconds  = 1209600  # 14 days
  visibility_timeout_seconds = 30

  tags = {
    Name        = "${var.project_name}-booking-confirmed-dlq"
    Project     = var.project_name
  }
}

# Main Queue
resource "aws_sqs_queue" "booking_confirmed" {
  name                       = "${var.project_name}-booking-confirmed"
  message_retention_seconds  = 86400   # 1 day
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 20      # long polling

  # Attach DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.booking_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project_name}-booking-confirmed"
    Project     = var.project_name
  }
}

# Queue Policy
# Allows booking service to publish
# Allows notification service to consume
resource "aws_sqs_queue_policy" "booking_confirmed" {
  queue_url = aws_sqs_queue.booking_confirmed.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBookingServicePublish"
        Effect = "Allow"
        Principal = {
          AWS = var.booking_service_role_arn
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.booking_confirmed.arn
      },
      {
        Sid    = "AllowNotificationServiceConsume"
        Effect = "Allow"
        Principal = {
          AWS = var.notification_service_role_arn
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.booking_confirmed.arn
      }
    ]
  })
}