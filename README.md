# laravel-kubernetes
This is a work in progress. The goal of the project is to deploy a laravel based application on AWS EKS.  This readme will provide more details on how to use the scripts in it as the project evolves.

## Basic Steps
* Create kubernetes cluster in EKS
* Configure Kubectl to work with the cluster
* Create EC2 nodes to be used with the cluster using cloudformation
* Launch application

## Useful Links
* https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html
* https://medium.com/containerum/how-to-easily-deploy-a-drupal-8-instance-on-kubernetes-b90acc7786b7
* https://learnk8s.io/blog/kubernetes-deploy-laravel-the-easy-way/
* https://medium.com/iplaya/how-to-deploy-laravel-application-to-kubernetes-9bc81d46eedf

## Useful kubectl commands
````
# get persistent volumes
kubectl get pvc

# get services
kubectl get services

# list pods with detail
kubectl get pods -o wide     

````
