#!/bin/sh
#
# This is a work in progress
#
# Run this script to create an aws cluster in EKS
#
# Usage: aws-init.sh <region> <clustername>

# Function:
# Create environments for central and cancernetwork using supplied db backups
# $name = 'lsgdevRD01'
# $role = 'arn:aws:iam::717590356715:role/awsk8mgmt'
# $subnet1 = 'subnet-072bce0e16e625de1'
# $subnet2 = 'subnet-00ce128a244ed83a3'
# $subnet3 = 'subnet-0feb1a10f6b36ee62'
# $securityGroup = 'sg-09bedc8b944e491e6'
# $region = 'us-east-1'

# Function:
# Create EKS cluster in AWS

# Collect parameters

region="$1"
clustername="$2"

if [[ "$1" = "" || "$2" = "" ]]; then
echo "###############################################################"
echo "# Parameter usage: aws-init.sh <region> <clustername>         #"
echo "#                                                             #"
echo "# region: eg: us-east-1                                       #"
echo "# clustername: eg: lsgdevRD01                                 #"
echo "###############################################################"
exit 0
fi

# Create EKS cluster
aws eks --region $region create-cluster --name $clustername --role-arn arn:aws:iam::717590356715:role/awsk8mgmt --resources-vpc-config subnetIds=subnet-072bce0e16e625de1,subnet-00ce128a244ed83a3,subnet-0feb1a10f6b36ee62,securityGroupIds=sg-09bedc8b944e491e6

# Get cluster status
# until my_cmd | grep -m 1 "String Im Looking For"; do : ; done ?
# until aws eks --region us-east-1 describe-cluster --name lsgdevRD01 --query cluster.status | grep -m 1 "create";
until aws eks --region $region describe-cluster --name $clustername --query cluster.status | grep -m 1 "ACTIVE";
do
  sleep 10;
  echo 'cluster status';
  aws eks --region $region describe-cluster --name $clustername --query cluster.status;
done

# update-kubeconfig to work with the cluster
aws eks --region $region update-kubeconfig --name $clustername

# test setup
sleep 2
kubectl get svc
