variable "region" {                # Mumbai region 
 default = "ap-south-1"
}

variable "ami_id" {                     # production AMI fresh needs to be configure 
    default = "ami-0fa52f1a01deb1658" 
}

variable "az_1a" {                       # Multi AZ 
    default = "ap-south-1a"
}

variable "az_1b" {                      # Multi AZ
    default = "ap-south-1b"
}

variable "db_password"{                     # RDS Creds 
    description = "RDS master password"
    type = string
    sensitive = true
}

