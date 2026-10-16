## Production Infra ## 
## VPC Section ##

resource "aws_vpc" "prod_vpc"{
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "fooddash-prod-vpc"
        Environment = "production"
        Project = "fooddash"
    }
}

##