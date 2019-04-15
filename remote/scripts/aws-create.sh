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

### Create EKS cluster ###
aws eks --region $region create-cluster --name $clustername --role-arn arn:aws:iam::717590356715:role/awsk8mgmt \
--resources-vpc-config subnetIds=subnet-072bce0e16e625de1,subnet-00ce128a244ed83a3,subnet-0feb1a10f6b36ee62,securityGroupIds=sg-09bedc8b944e491e6
sleep 10;
# Get cluster status
until aws eks --region $region describe-cluster --name $clustername --query cluster.status | grep -m 1 "ACTIVE";
do
  sleep 20;
  echo 'cluster status';
  aws eks --region $region describe-cluster --name $clustername --query cluster.status;
done

# update-kubeconfig to work with the cluster
aws eks --region $region update-kubeconfig --name $clustername

# test setup
sleep 2
kubectl get svc
###############################

### Create cloudformation stack ###
aws cloudformation create-stack --stack-name $clustername-workernodes \
--template-body https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-01-09/amazon-eks-nodegroup.yaml \
--parameters \
ParameterKey=ClusterName,ParameterValue=$clustername \
ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=sg-09bedc8b944e491e6 \
ParameterKey=NodeGroupName,ParameterValue=$clustername-A \
ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=1 \
ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=2 \
ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=3 \
ParameterKey=NodeInstanceType,ParameterValue=t3.small \
ParameterKey=NodeImageId,ParameterValue=ami-0c5b63ec54dd3fc38 \
ParameterKey=NodeVolumeSize,ParameterValue=20 \
ParameterKey=KeyName,ParameterValue=mattermost \
ParameterKey=VpcId,ParameterValue=vpc-0bd4afe4a308c146d \
ParameterKey=Subnets,ParameterValue=subnet-00ce128a244ed83a3\\,subnet-072bce0e16e625de1\\,subnet-0feb1a10f6b36ee62 \
--capabilities CAPABILITY_IAM

#wait until stack is ready
until aws cloudformation --region $region describe-stacks --stack-name $clustername-workernodes --query 'Stacks[0].StackStatus' --output text | grep -m 1 "CREATE_COMPLETE";
do
  sleep 10;
  echo 'stack status';
  aws cloudformation --region $region describe-stacks --stack-name $clustername-workernodes --query 'Stacks[0].StackStatus' --output text;
done
##########################

### Update kubectl to work with the new stack ###
role=$(aws cloudformation --region $region describe-stacks --stack-name $clustername-workernodes --query 'Stacks[0].Outputs[?OutputKey==`NodeInstanceRole`].OutputValue' --output text)
curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-01-09/aws-auth-cm.yaml
sed -i".original" "s~<ARN of instance role (not instance profile)>~$role~g" aws-auth-cm.yaml
kubectl apply -f aws-auth-cm.yaml
##################################

# ### Verify EC2 nodes are ready ###
# nodes=$(kubectl get nodes | grep NotReady | wc -l)
# sleep 5;
# until [ $nodes -eq 0 ]; do
#   sleep 2;
#   echo  'Waiting for nodes to become available'
# done
# echo 'Nodes are available'
# ##################################
echo  'Waiting for nodes to become available'
sleep 40
echo 'Nodes are available'
### Deploy Application ###
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

echo "##Defining persistent volume containers##"
kubectl apply -f ../manifest/laravel-persistentvolumeclaim.yaml
echo ''

echo "##Creating mysql container##"
kubectl apply -f ../manifest/laravel-mysql.yaml
echo ''

echo "##Verifying pods are available##"
kubectl get pods
echo ''

echo "##Building laravel container based on php 7.2##"
kubectl apply -f ../manifest/laravel.yaml
echo ''

echo "##Verifying services are available##"
kubectl get svc
echo ''
##################################

### Update settings file to include correct mysql IP ###
# get IP address of mysql service
mysql_ip=$(kubectl get svc laravel-mysql-service -o=jsonpath='{.spec.clusterIP}')
cp ../credentials/database.remote ../credentials/dbsettings.inc
sed "-i" "" "-e" "s~<mysql ip>~$mysql_ip~g" ../credentials/dbsettings.inc
podStatus=$(kubectl get pods -o=jsonpath='{..status.phase}')
#To Do: Fix this
# until [ "${podStatus}" = 'Running Running' ];
# do
#   echo 'Waiting for pods to become available';
#   sleep 1;
# done
sleep 60
echo 'Pods are ready'
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

echo 'Establishing datbase credentials '
podVariables=$(kubectl get pods -o=jsonpath='{..metadata.name}')
laravelPod=$(echo $podVariables | cut -f1 -d' ')
mysqlPod=$(echo $podVariables | cut -f2 -d' ')
#TODO: Change to .env
#kubectl cp ../credentials/dbsettings.inc $laravelPod:/var/www

#echo 'Importing Database'
#kubectl exec -it $mysqlPod  -- mysql -u root -proot_password laravel-database < ~/Documents/db_backups/february2019/stage-stonesmart-201902041425-before.sql

host=$(kubectl get services -o=jsonpath='{..hostname}')
echo 'Your site is running here' $host

#podVariables=$(kubectl get pods -o=jsonpath='{..metadata.name}')
#laravelPod=$(echo $podVariables | cut -f1 -d' ')
#kubectl exec -it $laravelPod -- /bin/bash

##################################
