output "service_account_name" {
  value = kubernetes_service_account.spark_reports_sa.metadata[0].name
}


#output "iam_role_arn" {
  #value = aws_iam_role.spark_reports_irsa_role.arn
#}
