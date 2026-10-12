#!/bin/bash
set -e

REGION="ap-south-2"
BASTION_ID="i-06496d878e64fe2fe"
APP_EC2_ID="i-04755f39f993686c5"
PRIVATE_ROUTE_TABLE_ID="rtb-0d4f1d68d438545fd"
ASG_NAME="fooddash-asg"
RDS_IDENTIFIER="fooddash"

echo "==> Scaling ASG down to 0..."
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name $ASG_NAME \
  --min-size 0 \
  --desired-capacity 0 \
  --region $REGION
echo "ASG scaled to 0."

echo "==> Stopping RDS..."
RDS_STATUS=$(aws rds describe-db-instances --db-instance-identifier $RDS_IDENTIFIER --query 'DBInstances[0].DBInstanceStatus' --output text --region $REGION 2>/dev/null || echo "notfound")
if [ "$RDS_STATUS" == "notfound" ] || [ "$RDS_STATUS" == "None" ]; then
  echo "RDS not found, skipping."
else
  aws rds stop-db-instance --db-instance-identifier $RDS_IDENTIFIER --region $REGION
  echo "RDS stop initiated (runs in background)."
fi

echo "==> Stopping EC2 instances..."
aws ec2 stop-instances --instance-ids $APP_EC2_ID $BASTION_ID --region $REGION
aws ec2 wait instance-stopped --instance-ids $APP_EC2_ID $BASTION_ID --region $REGION
echo "EC2 instances stopped."

echo "==> Deleting NAT Gateway..."
NAT_ID=$(aws ec2 describe-nat-gateways \
  --filter Name=state,Values=available \
  --query 'NatGateways[0].NatGatewayId' \
  --output text --region $REGION)

if [ "$NAT_ID" == "None" ] || [ -z "$NAT_ID" ]; then
  echo "No active NAT Gateway found, skipping."
else
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID --region $REGION
  echo "NAT Gateway $NAT_ID deletion initiated."
  echo "Waiting 60 seconds for NAT Gateway to delete..."
  sleep 60

  echo "==> Deleting NAT route from private route table..."
  aws ec2 delete-route \
    --route-table-id $PRIVATE_ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --region $REGION
  echo "Route deleted."

  echo "==> Releasing EIP..."
  EIP=$(aws ec2 describe-addresses \
    --query 'Addresses[?AssociationId==null].AllocationId' \
    --output text --region $REGION)
  if [ -n "$EIP" ]; then
    aws ec2 release-address --allocation-id $EIP --region $REGION
    echo "EIP $EIP released."
  else
    echo "No unassociated EIP found, skipping."
  fi
fi

echo ""
echo "✅ Shutdown complete! Resources stopped/deleted to save costs."
