region            = "us-east-2"
cluster_name      = "spark-cluster"

node_group_name   = "spark-node-group"

vm_size           = "t3.medium"
desired_capacity  = 2
min_capacity      = 1
max_capacity      = 3
bucket_name       = "s3upload-lambda-bucket"

vpc_cidr_block        = "10.0.0.0/16"

public_subnet_1_cidr  = "10.0.1.0/24"
public_subnet_2_cidr  = "10.0.2.0/24"

availability_zone_1   = "us-east-2a"
availability_zone_2   = "us-east-2b"

subnet_ids = [
  "subnet-0701d8c5265bf5079", # public-subnet-1
  "subnet-084772b6ba773dc79"  # public-subnet-2
]
