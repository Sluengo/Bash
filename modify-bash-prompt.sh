#!/bin/bash


# Retrieves Instance ID by curling the instance meta-data
INSTANCE_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`

# Queries Autoscaling API to retreive Autoscaling Group Name
AUTOSCALING_GROUP_NAME=`aws autoscaling describe-auto-scaling-instances --instance-ids $INSTANCE_ID| jq '.AutoScalingInstances[] |.AutoScalingGroupName'`
AUTOSCALING_GROUP_NAME=`echo $AUTOSCALING_GROUP_NAME | xargs`

# Uses the Autoscaling Group Name to query the API again for the Elastic Beanstalk Environment Nae
ENV_NAME=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $AUTOSCALING_GROUP_NAME | jq '.AutoScalingGroups[].Tags[] | select(.Key=="elasticbeanstalk:environment-name")| .Value'`
ENV_NAME=`echo $ENV_NAME | xargs`

sh -c "echo 'export NICKNAME=$ENV_NAME' > /etc/profile.d/prompt.sh"

sed 's|u@\\h|u@'"$ENV_NAME"'|g' /etc/bashrc > /etc/bashrc-new && mv /etc/bashrc-new /etc/bashrc -f
