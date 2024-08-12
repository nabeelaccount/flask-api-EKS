

Once you've created the EKS cluster, you can access it by updating you local machines kubeconfig as follows:
```
aws eks update-kubeconfig --name production-postgres-api --alias=production-postgres-api --region=us-east-
```