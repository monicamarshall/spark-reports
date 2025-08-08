terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

# Cluster details
data "aws_eks_cluster" "spark_cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "spark_cluster" {
  name = var.cluster_name
}

# NEW: Get account ID
data "aws_caller_identity" "current" {}

# Kubernetes provider config using EKS cluster details
provider "kubernetes" {
  host                   = data.aws_eks_cluster.spark_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.spark_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.spark_cluster.token
}

# Namespace
resource "kubernetes_namespace" "spark_reports" {
  metadata {
    name = "spark-reports"
  }
}

# IAM Role for IRSA
resource "aws_iam_role" "spark_reports_irsa_role" {
  name = "spark-reports-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.spark_cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.spark_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:spark-reports:spark-reports-sa"
          }
        }
      }
    ]
  })
}

# Attach AmazonS3FullAccess policy
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.spark_reports_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Service Account with IRSA annotation
resource "kubernetes_service_account" "spark_reports_sa" {
  metadata {
    name      = "spark-reports-sa"
    namespace = kubernetes_namespace.spark_reports.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.spark_reports_irsa_role.arn
    }
  }
}
