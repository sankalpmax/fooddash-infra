resource "aws_vpc" "fooddash_vpc" {     
    cidr_block = "10.1.0.0/16"
  
  tags = {
    name = "fooddash_vpc"
  }
}

resource "aws_internet_gateway" "fooddash_igw" {
    vpc_id = aws_vpc.fooddash_vpc.id

    tags = {
      name = "fooddash_igw"
    }
  
}

resource "aws_route_table" "public_foodapp_route" {
   vpc_id = aws_vpc.fooddash_vpc.id

   route {
    cidr_block = "0.0.0.0/0"
    gateway_id =  aws_internet_gateway.fooddash_igw.id
   }

   tags = {
     name = "public_route_table"
   }
}
 

resource "aws_route_table_association" "public_subnet_foodapp_az_2a" {
  route_table_id = aws_route_table.public_foodapp_route.id
  subnet_id = aws_subnet.public_subnet_foodapp_az_2a.id
  
}

resource "aws_route_table_association" "public_subnet_foodapp_az_2b" {
    route_table_id = aws_route_table.public_foodapp_route.id
    subnet_id = aws_subnet.public_subnet_foodapp_az_2b.id
  
}

resource "aws_subnet" "public_subnet_foodapp_az_2a" {     
  vpc_id = aws_vpc.fooddash_vpc.id
  availability_zone = "ap-south-2a"
  cidr_block = "10.1.1.0/24"

  tags = {
    name = "public_foodapp_subnet_2a"
  }
}

resource "aws_subnet" "private_subnet_foodapp_az_2a" {     
    vpc_id = aws_vpc.fooddash_vpc.id
    availability_zone = "ap-south-2a"
    cidr_block = "10.1.2.0/24"

    tags = {
      name = "private_foodapp_subnet_2a"
    }
  
}

resource "aws_subnet" "public_subnet_foodapp_az_2b" {       
    vpc_id = aws_vpc.fooddash_vpc.id
    availability_zone = "ap-south-2b"
    cidr_block = "10.1.3.0/24"

    tags = {
      name = "public_foodapp_subnet_2b"
    }
  
}

resource "aws_subnet" "private_subnet_foodapp_az_2b" {
  vpc_id = aws_vpc.fooddash_vpc.id
  availability_zone =  "ap-south-2b"
  cidr_block = "10.1.4.0/24"

  tags = {
    name = "private_foodapp_subnet_2b"
  }
  
}