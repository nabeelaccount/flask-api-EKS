# Creating a Flask API for Postgres payment transaction

This infrastructure is based on a minikube project that deploys a Flask API capable of passing through transactional data. You can find out more by visiting [flask-api-k8s](https://github.com/nabeelaccount/flask-api-k8s).

The infrastucture builds on the necessary components for automating and running a the API in aws.

Once you've created the EKS cluster, you can access it by updating you local machines kubeconfig as follows:
```
aws eks update-kubeconfig --name production-postgres-api --alias=production-postgres-api --region=us-east-
```

## Improvements

This is an ongoing project and constant improvements are made. 