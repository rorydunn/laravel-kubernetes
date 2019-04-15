#!/bin/sh
#
# This is a work in progress
#
# Run this script to create an aws cluster in EKS
#
# Usage: aws-init.sh <region> <clustername>

# Wait for cluster to be created
mysql_ip=$(kubectl get svc laravel-mysql-service -o=jsonpath='{.spec.clusterIP}')
cp ../credentials/database.remote ../credentials/dbsettings.inc
sed "-i" "" "-e" "s~<mysql ip>~$mysql_ip~g" ../credentials/dbsettings.inc
podStatus=$(kubectl get pods -o=jsonpath='{..status.phase}')
until [ "${podStatus}" = 'Running Running' ]; do
  echo 'Waiting for pods to become available';
  sleep 1;
done
echo 'Pods are ready'
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
podVariables=$(kubectl get pods -o=jsonpath='{..metadata.name}')
laravelPod=$(echo $podVariables | cut -f1 -d' ')
mysqlPod=$(echo $podVariables | cut -f2 -d' ')
kubectl cp ../credentials/dbsettings.inc $laravelPod:/var/www

kubectl exec -it $mysqlPod  -- mysql -u root -proot_password laravel-database < ~/Documents/db_backups/february2019/stage-stonesmart-201902041425-before.sql
