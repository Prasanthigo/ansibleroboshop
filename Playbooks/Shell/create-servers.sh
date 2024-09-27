#!/bin/bash

NAMES=$@
INSTANCE_TYPE=""
IMAGE_ID=ami-0b4f379183e5706b9
SECURITY_GROUP_ID=sg-0ac49767c0a3513e7
DOMAIN_NAME=hetvik.online
HOSTED_ZONE_ID=Z0220614ND8PFSAQRQUP

for i in $NAMES
do
  if [[ $i == "mongodb" || $i == "mysql" ]]; then
    INSTANCE_TYPE="t3.medium"
  else
    INSTANCE_TYPE="t2.micro"
  fi

  echo "Creating $i instance"

  # Launch the instance and request a public IP
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $IMAGE_ID \
    --instance-type $INSTANCE_TYPE \
    --security-group-ids $SECURITY_GROUP_ID \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" \
    --query "Instances[0].InstanceId" \
    --output text)

  # Wait for the instance to be in the "running" state
  echo "Waiting for $i instance to enter 'running' state..."
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID

  # Retrieve the public IP address after the instance is running
  PUBLIC_IP_ADDRESS=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

  if [ "$PUBLIC_IP_ADDRESS" == "None" ]; then
    echo "Error: Public IP not assigned to $i instance."
    exit 1
  fi

  echo "Created $i instance with Public IP: $PUBLIC_IP_ADDRESS"

  # Update Route 53 with the public IP address
  aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "'$i'.'$DOMAIN_NAME'",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{ "Value": "'$PUBLIC_IP_ADDRESS'" }]
      }
    }]
  }'

done
