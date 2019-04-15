#!/bin/sh
#
# Basic Steps
# 1. From: https://medium.com/containerum/how-to-easily-deploy-a-laravel-8-instance-on-kubernetes-b90acc7786b7
#   a. kubectl apply -f laravel-persistentvolumeclaim.yaml
#   b. kubectl apply -f laravel-mysql.yaml
#   c. kubectl get pods
#   d. kubectl apply -f laravel.yaml
#   e. kubectl get svc
# 2. Import database
#kubectl exec -it laravel-mysql-6fd9f5ddf7-v77k4  -- mysql -u root -proot_password laravel-database < ~/Documents/db_backups/february2019/stage-stonesmart-201902041425-before.sql
#kubectl exec -it laravel-7c8b7fbf6f-d6jvn -- /bin/bash

# Function:
# Create environments for central and cancernetwork using supplied db backups
#Parameters needed: git branch, Mysql db backup,
#branch = 'lsgdevRD01'
#db = 'arn:aws:iam::717590356715:role/awsk8mgmt'

echo "##Defining persistent volume containers##"
#kubectl apply -f laravel-persistentvolumeclaim.yaml
echo ''

echo "##Creating mysql container##"
kubectl apply -f laravel-mysql.yaml
echo ''

echo "##Verifying pods are available##"
kubectl get pods
echo ''

echo "##Building laravel container based on php 7.2##"
kubectl apply -f laravel.yaml
echo ''

echo "##Verifying services are available##"
kubectl get svc
echo ''
