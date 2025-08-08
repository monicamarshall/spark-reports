output "eks_node_group_name" {
  description = "The name of the EKS node group"
  value       = aws_eks_node_group.node_group.node_group_name
}

output "eks_node_group_role_arn" {
  description = "IAM Role ARN used by the EKS node group"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.name
}

output "s3_bucket_url" {
  description = "The URL of the S3 bucket"
  value       = "https://${aws_s3_bucket.project_bucket.bucket}.s3.amazonaws.com"
}
