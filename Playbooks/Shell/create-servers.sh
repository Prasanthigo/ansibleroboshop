NAMES=$@
INSTANCE_TYPE=""
IMAGE_ID=ami-0b4f379183e5706b9
SECURITY_GROUP_ID=sg-0ac49767c0a3513e7
DOMAIN_NAME=hetvik.online
HOSTED_ZONE_ID=Z0220614ND8PFSAQRQUP

for i in $NAMES
do
  if [[ $i == "mongodb" || $i == "mysql" ]]; then  # Corrected the if condition syntax
    INSTANCE_TYPE="t3.medium"
  else
    INSTANCE_TYPE="t2.micro"
  fi

  echo "Creating $i instance"

  # Corrected PrivateIpAddress retrieval and closing parentheses
  IP_ADDRESS=$(aws ec2 run-instances --image-id $IMAGE_ID --instance-type $INSTANCE_TYPE --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" | jq -r '.Instances[0].PublicIpAddress')

  echo "Created $i instance: $IP_ADDRESS"

  # Fixed quotes for AWS CLI Route 53 command
  aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "'$i'.'$DOMAIN_NAME'",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{ "Value": "'$IP_ADDRESS'" }]
      }
    }]
  }'

done
