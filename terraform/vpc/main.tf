## VPC Section ##
resource "aws_vpc" "food_app_vpc" {
    cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terraform_app_vpc"
    Project = "fooddash"
  }
}


## IGW Section ##
resource "aws_internet_gateway" "fooddash" {
    vpc_id = aws_vpc.food_app_vpc.id
      
      tags = {
        Name = "fooddash-igw"
      }
}


## Public Route Table and it's Association Section ##


resource "aws_route_table" "food_app_public_route" {
    vpc_id = aws_vpc.food_app_vpc.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id =  aws_internet_gateway.fooddash.id
  }
  tags = {
    Name = "terraform_public_route"
  }
}

resource "aws_route_table_association" "terraform_public_route_2a" {
    route_table_id = aws_route_table.food_app_public_route.id
    subnet_id = aws_subnet.pub_subnet_az_2a.id
  
}

resource "aws_route_table_association" "terraform_public_route_2b" {
    route_table_id = aws_route_table.food_app_public_route.id
    subnet_id = aws_subnet.pub_subnet_az_2b.id
  
}

## EIP for NAT ##
## Commented out to avoid costs until EC2 is deployed ##
# resource "aws_eip" "fooddash_eip" {
#      domain = "vpc"
# }

## NAT ##
## Commented out to avoid costs until EC2 is deployed ##
# resource "aws_nat_gateway" "nat_fooddash" {
#     subnet_id     = aws_subnet.pub_subnet_az_2a.id
#     allocation_id = aws_eip.fooddash_eip.id
#     tags = {
#       Name = "nat_for_fooddash"
#     }
# }

## Security Groups Section ##
## We use inline ingress for declaring the SG rules ##
resource "aws_security_group" "food_app_alb_sg" {
  name = "food_app_alb_sg"
  description = "security group for receving the authorised traffic"
  vpc_id = aws_vpc.food_app_vpc.id

    ingress  {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  tags = {
    name = "food_app_alb_sg"
  }
}

resource "aws_security_group" "food_app_ec2_sg" {
    name = "food_app_ec2_sg"
    description = "security group for receving the authorised traffic from alb security group and the RDS security group "
    vpc_id = aws_vpc.food_app_vpc.id

    ingress  {
        from_port ="3000"
        to_port="3000"
        protocol = "tcp"
        security_groups = [aws_security_group.food_app_alb_sg.id]
    }
    ingress  {
        from_port = "3001"
        to_port = "3001"
        protocol = "tcp"
        security_groups = [aws_security_group.food_app_alb_sg.id] 

    }
    ingress {
        from_port = "3002"
        to_port = "3002"
        protocol = "tcp"
        security_groups = [aws_security_group.food_app_alb_sg.id ]
    }
    ingress {
        from_port = "3003"
        to_port = "3003"
        protocol = "tcp"
        security_groups = [aws_security_group.food_app_alb_sg.id]
    }

    ingress  {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["49.43.241.218/32"]
    }
  
}

resource "aws_security_group" "food_app_rds_sg" {
    name = "food_app_rds_sg"
    description = "for secure outbound and inbound traffic"
    vpc_id = aws_vpc.food_app_vpc.id

    ingress {
        from_port = "5432"
        to_port = "5432"
        protocol = "tcp"
        security_groups = [aws_security_group.food_app_ec2_sg.id]
    }
  
}



## Private Route Table and Associations ##

resource "aws_route_table" "terraform_private_route" {
    vpc_id = aws_vpc.food_app_vpc.id

   # route {
    #    cidr_block = "0.0.0.0/0"
    #    nat_gateway_id = aws_nat_gateway.nat_fooddash.id
    #}
    
    tags = {
      Name = "terraform_private_route"
    }
  
}

resource "aws_route_table_association" "terraform_private_subnet_az_2a" {
    route_table_id = aws_route_table.terraform_private_route.id
    subnet_id = aws_subnet.private_subnet_az_2a.id
}

resource "aws_route_table_association" "terraform_private_subnet_az_2b" {
    route_table_id = aws_route_table.terraform_private_route.id
    subnet_id = aws_subnet.private_subnet_az_2b.id
  
}

## RDS Section ##

resource "aws_db_subnet_group" "primary_subnet_rds_az_2a" {
  name = "rds_private_subnet_grp"
  subnet_ids = [ aws_subnet.private_subnet_az_2a.id , aws_subnet.private_subnet_az_2b.id ]

  tags = {
    name =  "rds_private_subnet_grp"
  }
}

resource "aws_db_instance" "fooddash_db_instance" {
 engine = "postgres"
 engine_version = "18.3"
 instance_class = "db.t4g.micro"
 allocated_storage = 20
 db_name = "fooddash_db_instance" 
 username = "postgress"
 password = var.db_password
 db_subnet_group_name = aws_db_subnet_group.primary_subnet_rds_az_2a.name
 vpc_security_group_ids = [aws_security_group.food_app_rds_sg.id] 
 multi_az = false
 skip_final_snapshot = true
  
}
## Subnets's Section ##


resource "aws_subnet" "pub_subnet_az_2a"{
    vpc_id = aws_vpc.food_app_vpc.id
    cidr_block = "10.0.1.0/24"  
    availability_zone = "ap-south-2a"

    tags = {
        Name = "terraform_pub_subnet_az_2a"
        Project = "fooddash"
    }
}

resource "aws_subnet" "private_subnet_az_2a"{
    vpc_id = aws_vpc.food_app_vpc.id
    cidr_block = "10.0.2.0/24" 
    availability_zone = "ap-south-2a"

    tags = {
        Name = "terraform_private_subnet_az_2a"
        Project = "fooddash"
    }
}

resource "aws_subnet" "pub_subnet_az_2b"{
    vpc_id = aws_vpc.food_app_vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-south-2b"

    tags = {
        Name = "terraform_pub_subnet_az_2b"
        Project = "fooddash"
    }
}

resource "aws_subnet" "private_subnet_az_2b"{
    vpc_id = aws_vpc.food_app_vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "ap-south-2b"

    tags = {
        Name = "terraform_private_subnet_az_2b"
        Project = "fooddash"
    }
}


