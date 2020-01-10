#!/bin/bash

aws ec2 describe-instances | jq -r '.Reservations[].Instances[]|.PrivateIpAddress+ " : " + (.Tags[]?|select(.["Key"] == "Name")|.Value)' > /etc/hosts
sed -i 's/:/ /g' /etc/hosts

echo "127.0.0.1 localhost" >> /etc/hosts
