output "cluster_role_arn" {
  value = aws_iam_role.cluster_role.arn
}

output "node_role_arn" {
  value = aws_iam_role.node_role.arn
}

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller.arn
}

# output "booking_service_role_arn" {
#   value = aws_iam_role.booking_service.arn
# }

# output "notification_service_role_arn" {
#   value = aws_iam_role.notification_service.arn
# }

# output "all_services_role_arn" {
#   value = aws_iam_role.all_services.arn
# }