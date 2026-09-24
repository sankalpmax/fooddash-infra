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
}

resource "aws_route_table_association" "terraform_public_route_2a" {
    route_table_id = aws_route_table.food_app_public_route.id
    subnet_id = aws_subnet.pub_subnet_az_2a.id
  
}

resource "aws_route_table_association" "terraform_public_route_2b" {
    route_table_id = aws_route_table.food_app_public_route.id
    subnet_id = aws_subnet.pub_subnet_az_2b.id
  
}

## Private Route Table and Associations ##
## Private route table - No routes for now 
## NAT Gateway route 0.0.0.0/0 will be added in the future
resource "aws_route_table" "terraform_private_route" {
    vpc_id = aws_vpc.food_app_vpc.id
    
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


