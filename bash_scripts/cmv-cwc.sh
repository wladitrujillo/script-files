#!/bin/sh
#
env=$1
version=$2

if [ ! "$env" ] || [ ! "$version" ]
then
  echo "environment and version is required example: $0 dev1 2.46.13"
  exit
fi

case $env in

  'dev')
    account=573946347747
    profile=${account}_COBDeveloper
    targetPath=~/cmv-cwc-dev
    ;;

  'qa')
    account=566383216324
    profile=${account}_COBSupport
    targetPath=~/cmv-cwc-qa
    ;;

  *)
    echo 'environment not valid allowed dev qa'
    exit
    ;;
esac

region=us-east-1
imageTag=producto-$env-cwc-$version
containerName=$imageTag

echo 'Login aws ecr profile:' $profile
aws ecr --profile $profile get-login-password --region $region | docker login --username AWS --password-stdin $account.dkr.ecr.$region.amazonaws.com

echo 'pull imageTag:' $imageTag
docker pull $account.dkr.ecr.$region.amazonaws.com/cobis/cwc-cloud:$imageTag

echo 'run container:' $imageTag
docker run --name $containerName -p 8080:8080 -d $account.dkr.ecr.$region.amazonaws.com/cobis/cwc-cloud:$imageTag 

targetPath=$(pwd)

echo 'Copy cobishome-web to:' $targetPath
docker cp $containerName:/home/cobisuser/cobishome-web $targetPath
echo 'Copy tomcat to:' $targetPath
docker cp $containerName:/usr/local/tomcat $targetPath
echo 'stopping docker:' $containerName
docker stop $containerName


if [ -d $targetPath/cwc-assets ]; then
    echo 'Directory exists'
else
    echo 'Directory cwc-assets does not exist'
    exit
fi

infrastructurePath=$targetPath/cobishome-web/cwc/infrastructure/
cobisContainerPath=$targetPath/cobishome-web/cwc/services-as/cobis-container/
tomcatBinPath=$targetPath/tomcat/bin/

echo 'Copy cwc-log-config.xml to: ' $infrastructurePath
cp $targetPath/cwc-assets/cwc-log-config.xml $infrastructurePath
echo 'Copy cobis-container-config.xml settings to: ' $cobisContainerPath
cp $targetPath/cwc-assets/cobis-container-config.xml $cobisContainerPath 
echo 'Copy setenv.sh to: ' $tomcatBinPath
cp $targetPath/cwc-assets/cmv/setenv-$env.sh $tomcatBinPath/setenv.sh

