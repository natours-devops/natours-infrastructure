resource "aws_eks_pod_identity_association" "alb_controller" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = var.alb_controller_role_arn
}

resource "aws_eks_pod_identity_association" "booking_service" {
  cluster_name    = var.cluster_name
  namespace       = var.application_namespace
  service_account = "booking-service-sa"
  role_arn        = var.booking_service_role_arn
}

resource "aws_eks_pod_identity_association" "notification_service" {
  cluster_name    = var.cluster_name
  namespace       = var.application_namespace
  service_account = "notification-service-sa"
  role_arn        = var.notification_service_role_arn
}

resource "aws_eks_pod_identity_association" "all_services" {
  cluster_name    = var.cluster_name
  namespace       = var.application_namespace
  service_account = "all-services-sa"
  role_arn        = var.all_services_role_arn
}