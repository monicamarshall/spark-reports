provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "arn:aws:eks:us-east-2:828909213317:cluster/spark-cluster"
}
