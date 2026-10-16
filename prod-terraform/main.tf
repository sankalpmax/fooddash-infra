## Production Infrastructure for FoodDash ##
## Region: ap-south-1 (Mumbai) ##

## VPC Section ##
resource "aws_vpc" "prod_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "fooddash-prod-vpc"
    Environment = "production"
    Project     = "fooddash"
  }
}

## Internet Gateway ##
resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name        = "fooddash-prod-igw"
    Environment = "production"
  }
}

## Subnets Section ##
resource "aws_subnet" "pub_subnet_az_1a" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.az_1a

  tags = {
    Name        = "fooddash-prod-public-1a"
    Environment = "production"
    Project     = "fooddash"
  }
}

resource "aws_subnet" "pub_subnet_az_1b" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.az_1b

  tags = {
    Name        = "fooddash-prod-public-1b"
    Environment = "production"
    Project     = "fooddash"
  }
}

resource "aws_subnet" "private_subnet_az_1a" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.az_1a

  tags = {
    Name        = "fooddash-prod-private-1a"
    Environment = "production"
    Project     = "fooddash"
  }
}

resource "aws_subnet" "private_subnet_az_1b" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.az_1b

  tags = {
    Name        = "fooddash-prod-private-1b"
    Environment = "production"
    Project     = "fooddash"
  }
}

## EIP for NAT Gateway ##
resource "aws_eip" "prod_nat_eip" {
  domain = "vpc"

  tags = {
    Name        = "fooddash-prod-nat-eip"
    Environment = "production"
  }
}

## NAT Gateway ##
resource "aws_nat_gateway" "prod_nat" {
  allocation_id = aws_eip.prod_nat_eip.id
  subnet_id     = aws_subnet.pub_subnet_az_1a.id

  tags = {
    Name        = "fooddash-prod-nat"
    Environment = "production"
  }

  depends_on = [aws_internet_gateway.prod_igw]
}

## Public Route Table ##
resource "aws_route_table" "prod_public_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_igw.id
  }

  tags = {
    Name        = "fooddash-prod-public-rt"
    Environment = "production"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.pub_subnet_az_1a.id
  route_table_id = aws_route_table.prod_public_rt.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.pub_subnet_az_1b.id
  route_table_id = aws_route_table.prod_public_rt.id
}

## Private Route Table ##
resource "aws_route_table" "prod_private_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.prod_nat.id
  }

  tags = {
    Name        = "fooddash-prod-private-rt"
    Environment = "production"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_subnet_az_1a.id
  route_table_id = aws_route_table.prod_private_rt.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_subnet_az_1b.id
  route_table_id = aws_route_table.prod_private_rt.id
}

## Security Groups ##

## ALB Security Group ##
resource "aws_security_group" "prod_alb_sg" {
  name        = "fooddash-prod-alb-sg"
  description = "Security group for production ALB"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "fooddash-prod-alb-sg"
    Environment = "production"
  }
}

## EC2 Security Group ##
resource "aws_security_group" "prod_ec2_sg" {
  name        = "fooddash-prod-ec2-sg"
  description = "Security group for production EC2 instances"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_alb_sg.id]
  }

  ingress {
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_alb_sg.id]
  }

  ingress {
    from_port       = 3002
    to_port         = 3002
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_alb_sg.id]
  }

  ingress {
    from_port       = 3003
    to_port         = 3003
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.43.241.218/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "fooddash-prod-ec2-sg"
    Environment = "production"
  }
}

## RDS Security Group ##
resource "aws_security_group" "prod_rds_sg" {
  name        = "fooddash-prod-rds-sg"
  description = "Security group for production RDS"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_ec2_sg.id]
  }

  tags = {
    Name        = "fooddash-prod-rds-sg"
    Environment = "production"
  }
}

## IAM Role for EC2 ##
data "aws_iam_policy_document" "prod_ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "prod_ec2_role" {
  name               = "fooddash-prod-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.prod_ec2_assume_role.json

  tags = {
    Name        = "fooddash-prod-ec2-role"
    Environment = "production"
  }
}

data "aws_iam_policy_document" "prod_ec2_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["arn:aws:secretsmanager:ap-south-1:926239637076:secret:fooddash/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:*",
      "ssm:UpdateInstanceInformation",
      "ssm:GetParameter"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::fooddash-frontend-production-2026/*"]
  }
}

resource "aws_iam_policy" "prod_ec2_policy" {
  name        = "fooddash-prod-ec2-policy"
  description = "FoodDash production EC2 policy"
  policy      = data.aws_iam_policy_document.prod_ec2_policy.json
}

resource "aws_iam_role_policy_attachment" "prod_ec2_attach" {
  role       = aws_iam_role.prod_ec2_role.name
  policy_arn = aws_iam_policy.prod_ec2_policy.arn
}

resource "aws_iam_instance_profile" "prod_ec2_profile" {
  name = "fooddash-prod-ec2-profile"
  role = aws_iam_role.prod_ec2_role.name
}

## ALB Target Groups ##
resource "aws_lb_target_group" "prod_frontend_tg" {
  name     = "fooddash-prod-frontend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod_vpc.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "fooddash-prod-frontend-tg"
    Environment = "production"
  }
}

resource "aws_lb_target_group" "prod_user_tg" {
  name     = "fooddash-prod-user-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod_vpc.id

  health_check {
    path                = "/api/users/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "fooddash-prod-user-tg"
    Environment = "production"
  }
}

resource "aws_lb_target_group" "prod_restaurant_tg" {
  name     = "fooddash-prod-restaurant-tg"
  port     = 3002
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod_vpc.id

  health_check {
    path                = "/api/restaurants/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "fooddash-prod-restaurant-tg"
    Environment = "production"
  }
}

resource "aws_lb_target_group" "prod_order_tg" {
  name     = "fooddash-prod-order-tg"
  port     = 3003
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod_vpc.id

  health_check {
    path                = "/api/orders/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "fooddash-prod-order-tg"
    Environment = "production"
  }
}

## Application Load Balancer ##
resource "aws_lb" "prod_alb" {
  name               = "fooddash-prod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.prod_alb_sg.id]
  subnets            = [aws_subnet.pub_subnet_az_1a.id, aws_subnet.pub_subnet_az_1b.id]

  enable_deletion_protection = false

  tags = {
    Name        = "fooddash-prod-alb"
    Environment = "production"
  }
}

## ALB Listener ##
resource "aws_lb_listener" "prod_http" {
  load_balancer_arn = aws_lb.prod_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_frontend_tg.arn
  }
}

## ALB Listener Rules ##
resource "aws_lb_listener_rule" "prod_user" {
  listener_arn = aws_lb_listener.prod_http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_user_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/users", "/api/users/*"]
    }
  }
}

resource "aws_lb_listener_rule" "prod_restaurant" {
  listener_arn = aws_lb_listener.prod_http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_restaurant_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/restaurants", "/api/restaurants/*"]
    }
  }
}

resource "aws_lb_listener_rule" "prod_order" {
  listener_arn = aws_lb_listener.prod_http.arn
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_order_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/orders", "/api/orders/*"]
    }
  }
}

## Launch Template ##
resource "aws_launch_template" "prod_lt" {
  name          = "fooddash-prod-lt"
  image_id      = var.ami_id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.prod_ec2_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.prod_ec2_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update and install dependencies
    sudo apt update && sudo apt upgrade -y
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs git
    sudo npm install -g pm2 serve dotenv-cli

    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt install unzip -y
    unzip awscliv2.zip
    sudo ./aws/install

    # Clone repository
    git clone https://github.com/sankalpmax/fooddash.git /home/ubuntu/fooddash
    cd /home/ubuntu/fooddash

    # Install dependencies
    cd user-service && npm install && cd ..
    cd restaurant-service && npm install && cd ..
    cd order-service && npm install && cd ..
    cd frontend && npm install && npm run build && cd ..

    # Fetch secrets from Secrets Manager
    SECRET=$(aws secretsmanager get-secret-value \
      --secret-id "fooddash/prod-db-credentials" \
      --region ap-south-1 \
      --query 'SecretString' --output text)

    DB_HOST=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['DB_HOST'])")
    DB_USER=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['DB_USER'])")
    DB_PASSWORD=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['DB_PASSWORD'])")
    DB_NAME=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['DB_NAME'])")
    JWT_SECRET=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['JWT_SECRET'])")

    # Create .env files
    cat > /home/ubuntu/fooddash/user-service/.env << ENVEOF
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
PORT=3001
JWT_SECRET=$JWT_SECRET
ENVEOF

    cat > /home/ubuntu/fooddash/restaurant-service/.env << ENVEOF
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
PORT=3002
JWT_SECRET=$JWT_SECRET
ENVEOF

    cat > /home/ubuntu/fooddash/order-service/.env << ENVEOF
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
PORT=3003
JWT_SECRET=$JWT_SECRET
ENVEOF

    # Set permissions
    chown -R ubuntu:ubuntu /home/ubuntu/fooddash

    # Start services with pm2
    sudo -u ubuntu pm2 start /home/ubuntu/fooddash/user-service/src/index.js --name user-service
    sudo -u ubuntu pm2 start /home/ubuntu/fooddash/restaurant-service/src/index.js --name restaurant-service
    sudo -u ubuntu pm2 start /home/ubuntu/fooddash/order-service/src/index.js --name order-service
    sudo -u ubuntu pm2 start /usr/bin/serve --name frontend -- -s /home/ubuntu/fooddash/frontend/dist -p 3000

    # Save pm2 config
    sudo -u ubuntu pm2 startup systemd -u ubuntu --hp /home/ubuntu
    sudo -u ubuntu pm2 save
    EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "fooddash-prod-app-server"
      Environment = "production"
      Project     = "fooddash"
    }
  }

  tags = {
    Name        = "fooddash-prod-lt"
    Environment = "production"
  }
}

## Auto Scaling Group ##
resource "aws_autoscaling_group" "prod_asg" {
  name = "fooddash-prod-asg"

  vpc_zone_identifier = [
    aws_subnet.private_subnet_az_1a.id,
    aws_subnet.private_subnet_az_1b.id
  ]

  min_size         = 0
  max_size         = 3
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.prod_lt.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.prod_frontend_tg.arn,
    aws_lb_target_group.prod_user_tg.arn,
    aws_lb_target_group.prod_restaurant_tg.arn,
    aws_lb_target_group.prod_order_tg.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 600

  tag {
    key                 = "Name"
    value               = "fooddash-prod-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "production"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "fooddash"
    propagate_at_launch = true
  }
}

## RDS DB Subnet Group ##
resource "aws_db_subnet_group" "prod_db_subnet_group" {
  name       = "fooddash-prod-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_az_1a.id, aws_subnet.private_subnet_az_1b.id]

  tags = {
    Name        = "fooddash-prod-db-subnet-group"
    Environment = "production"
  }
}

## RDS PostgreSQL Database ##
resource "aws_db_instance" "prod_rds" {
  identifier             = "fooddash-prod-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  db_name                = "fooddash_prod"
  username               = "postgres"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.prod_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.prod_rds_sg.id]
  multi_az               = false
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name        = "fooddash-prod-rds"
    Environment = "production"
  }
}
