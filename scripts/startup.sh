#!/bin/bash
set -e

REGION="ap-south-2"
BASTION_ID="i-06496d878e64fe2fe"
APP_EC2_ID="i-04755f39f993686c5"
PUBLIC_SUBNET_ID="subnet-05fbaaea33c81a6b6"
PRIVATE_ROUTE_TABLE_ID="rtb-0d4f1d68d438545fd"
ASG_NAME="fooddash-asg"
RDS_IDENTIFIER="fooddash"

echo "==> Starting EC2 instances..."
aws ec2 start-instances --instance-ids $APP_EC2_ID $BASTION_ID --region $REGION
echo "Waiting for EC2 instances to start..."
aws ec2 wait instance-running --instance-ids $APP_EC2_ID $BASTION_ID --region $REGION
echo "EC2 instances started."

echo "==> Starting RDS..."
RDS_STATUS=$(aws rds describe-db-instances --db-instance-identifier $RDS_IDENTIFIER --query 'DBInstances[0].DBInstanceStatus' --output text --region $REGION 2>/dev/null || echo "notfound")
if [ "$RDS_STATUS" == "notfound" ] || [ "$RDS_STATUS" == "None" ]; then
  echo "RDS not found — create it manually in AWS Console before starting services."
else
  aws rds start-db-instance --db-instance-identifier $RDS_IDENTIFIER --region $REGION
  echo "Waiting for RDS to become available (this takes ~3-5 mins)..."
  aws rds wait db-instance-available --db-instance-identifier $RDS_IDENTIFIER --region $REGION
  echo "RDS started."
fi

echo "==> Creating NAT Gateway..."
EIP=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text --region $REGION)
echo "EIP allocated: $EIP"
NAT=$(aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET_ID --allocation-id $EIP --query 'NatGateway.NatGatewayId' --output text --region $REGION)
echo "Waiting for NAT Gateway to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT --region $REGION
echo "NAT Gateway created: $NAT"

echo "==> Updating private route table..."
aws ec2 create-route \
  --route-table-id $PRIVATE_ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT \
  --region $REGION
echo "Route updated."

echo "==> Scaling ASG up..."
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name $ASG_NAME \
  --min-size 1 \
  --desired-capacity 1 \
  --region $REGION
echo "ASG scaled to 1."

echo ""
echo "✅ Startup complete!"
echo "NAT Gateway ID: $NAT (save this for shutdown)"
echo "EIP Allocation ID: $EIP (save this for shutdown)"
