#!/bin/bash

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)
    
    case "$KEY" in
        REGION)
            REGION=${VALUE}
        ;;
        VPC_ID)
            VPC_ID=${VALUE}
        ;;
        PRODUCT_VALUE)
            PRODUCT_VALUE=${VALUE}
        ;;
        ENV_VALUE)
            ENV_VALUE=${VALUE}
        ;;
        *)
    esac
done

echo "This script will tag: EC2 Instances, EBS Volumes & Security Groups in the AWS Region: $REGION under the VPC: $VPC_ID with the following tags: Key=product,Value=$PRODUCT_VALUE Key=env,Value=$ENV_VALUE"

# tag instances
aws ec2 describe-instances --region $REGION --filter Name=vpc-id,Values=$VPC_ID --query 'Reservations[*].Instances[*].[InstanceId]' --output text  | \
while read line ; 
do
    echo "Creating tags product:$PRODUCT_VALUE & env:$ENV_VALUE on Instance: $line" ; 
    aws ec2 create-tags --resources $line --tags Key=product,Value=$PRODUCT_VALUE Key=env,Value=$ENV_VALUE ; 
done

# tag volumes
aws ec2 describe-instances --region $REGION --filter Name=vpc-id,Values=$VPC_ID --query 'Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId' --output text | \
while read line ;
do 
    echo "Creating tags product:$PRODUCT_VALUE & env:$ENV_VALUE on Volume(s): $line" ;
    aws ec2 create-tags --resources $line --tags Key=product,Value=$PRODUCT_VALUE Key=env,Value=$ENV_VALUE ;
done

# tag security groups
aws ec2 describe-security-groups --region $REGION --filter Name=vpc-id,Values=$VPC_ID --query 'SecurityGroups[*].GroupId' --output text | \
while read line ;
do 
    echo "Creating tags product:$PRODUCT_VALUE & env:$ENV_VALUE on security group: $line" ;
    aws ec2 create-tags --resources $line --tags Key=product,Value=$PRODUCT_VALUE Key=env,Value=$ENV_VALUE ;
done