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

# EKS cluster data
data "aws_eks_cluster" "spark_cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "spark_cluster" {
  name = var.cluster_name
}

# Your AWS account (may be useful elsewhere)
data "aws_caller_identity" "current" {}

# ------------------------------
# Create the IAM OIDC provider (IRSA prerequisite)
# ------------------------------
data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.spark_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.spark_cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

# ------------------------------
# Kubernetes provider using EKS
# ------------------------------
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

# ------------------------------
# IAM Role for Service Account (IRSA)
# Trust only the service account: spark-reports/spark-reports-sa
# ------------------------------
data "aws_iam_policy_document" "spark_reports_irsa_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.spark_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:spark-reports:spark-reports-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.spark_cluster.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "spark_reports_irsa_role" {
  name               = "spark-reports-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.spark_reports_irsa_trust.json
}

# S3 permissions (broad for now; tighten later)
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.spark_reports_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Kubernetes Service Account annotated with the role
resource "kubernetes_service_account" "spark_reports_sa" {
  metadata {
    name      = "spark-reports-sa"
    namespace = kubernetes_namespace.spark_reports.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.spark_reports_irsa_role.arn
    }
  }
}
