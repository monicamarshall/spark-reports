This error means your kubectl is still pointing to your old AKS (Azure Kubernetes Service) cluster rather than your new EKS (AWS Elastic Kubernetes Service) cluster.

The error:

couldn't get current server API group list:
Get "https://myaksdns-t2zqpykw.hcp.eastus2.azmk8s.io:443/api?timeout=32s":
dial tcp: lookup myaksdns-t2zqpykw.hcp.eastus2.azmk8s.io: no such host
...is because the kubeconfig file (~/.kube/config) still contains or defaults to your old AKS context, which no longer exists or is unreachable.

How to Fix It (Use Your EKS Cluster)
Run the following command to update your kubeconfig to point to your new EKS cluster:

aws eks update-kubeconfig --region us-east-2 --name spark-cluster
This will:

Fetch the EKS cluster endpoint

Update your local ~/.kube/config

Set the current context to arn:aws:eks:...:cluster/spark-cluster

Then verify the context is set:

kubectl config current-context
It should say something like:

arn:aws:eks:us-east-2:<your-account-id>:cluster/spark-cluster

kubectl cluster-info
🔁 Optional: Clear or Rename the Old AKS Context
If you want to avoid confusion later, you can clean up the AKS context:

kubectl config delete-context <name-of-aks-context>
kubectl config delete-cluster <name-of-aks-cluster>
kubectl config delete-user <aks-user-name>
You can list all contexts with:

kubectl config get-contexts


Access the ArgoCD UI:

kubectl port-forward svc/argocd-server -n argocd 8080:443
Then go to https://localhost:8080

Retrieve the default admin password:

kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d


PS C:\data\EclipseAWSLambda\reports-demo\terraform-argocd> kubectl get svc -n argocd
NAME                                      TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)                      AGE
argocd-applicationset-controller          ClusterIP      172.20.57.50     <none>                                                                   7000/TCP,8080/TCP            9m18s
argocd-dex-server                         ClusterIP      172.20.194.8     <none>                                                                   5556/TCP,5557/TCP,5558/TCP   9m17s
argocd-metrics                            ClusterIP      172.20.253.43    <none>                                                                   8082/TCP                     9m17s
argocd-notifications-controller-metrics   ClusterIP      172.20.9.211     <none>                                                                   9001/TCP                     9m17s
argocd-redis                              ClusterIP      172.20.87.73     <none>                                                                   6379/TCP                     9m16s
argocd-repo-server                        ClusterIP      172.20.188.112   <none>                                                                   8081/TCP,8084/TCP            9m16s
argocd-server                             LoadBalancer   172.20.29.179    af31a9670cc654140b88880db97c3afc-694698367.us-east-2.elb.amazonaws.com   80:31594/TCP,443:30176/TCP   9m15s
argocd-server-metrics                     ClusterIP      172.20.216.93    <none>     

In Powershell

PS C:\data\EclipseAWSLambda\reports-demo\terraform-argocd> $encoded = kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"
PS C:\data\EclipseAWSLambda\reports-demo\terraform-argocd> [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
LOVNmC-buV9AtjbW

In bash

kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

PS C:\data\EclipseAWSLambda\reports-demo\terraform-argocd> [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
LOVNmC-buV9AtjbW


PS C:\data\EclipseAWSLambda\reports-demo\terraform-argocd> nslookup af31a9670cc654140b88880db97c3afc-694698367.us-east-2.elb.amazonaws.com
Server:  UnKnown
Address:  172.17.3.1


What You Got Is Correct
You received this external hostname from your ArgoCD LoadBalancer:

af31a9670cc654140b88880db97c3afc-694698367.us-east-2.elb.amazonaws.com



# Deploying ArgoCD on Azure Kubernetes Service (AKS) using Terraform By Raghu The Security Expert

## Introduction
This guide provides step-by-step instructions to deploy ArgoCD on AKS using Terraform, facilitating a GitOps workflow on Azure.

## Prerequisites
- **Kubectl**: Installed. Download here: [kubectl for Windows](https://dl.k8s.io/release/v1.28.9/bin/windows/amd64/kubectl.exe)
- **Azure CLI**: Installed and authenticated with `az login`.
- **AKS Credentials (AKS is up and running)**: Obtain with `az aks get-credentials --resource-group myAksResourceGroup --name myAksCluster`.
- **Visual Studio Code Base64 Decode and Encode Extension**: Installed for handling base64 decodings. Will be used to decode the initial ArgoCD admin password.

## Terraform Workflow
```bash
# Step 1: Initialize your Terraform workspace
terraform init

# Step 2: Generate and show an execution plan
terraform plan

# Step 3: Apply the changes required to reach the desired state of the configuration
terraform apply

# Step 4: Retrieve the ArgoCD default admin(username) password and decode it using Base64 extension
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"

# Step 5: Destroy all resources created by the Terraform configuration
terraform destroy
```

Helpful Terraform Links:
- [Terraform Language Documentation](https://www.terraform.io/docs/language/index.html)
- [Resource: azure_registry](https://registry.terraform.io/namespaces/Azure)

