terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
      ## will need to terraform init -upgrade 
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}


variable "instancetype" {
  type = string
  default = "t2.micro"
  description = "What type of instance do you want"
  
}

# Create a VPC
resource "aws_vpc" "org1_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "org1 Network"
  }

}
# Create a VPC org2
resource "aws_vpc" "org2_vpc" {
  cidr_block = "172.0.0.0/16"
  tags = {
    Name = "org2 Network"
  }

}

##subnets
resource "aws_subnet" "org1_public_subnet" {
  vpc_id            = aws_vpc.org1_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "org1_public_subnet"
  }

}
resource "aws_subnet" "org1_private_subnet" {
  vpc_id            = aws_vpc.org1_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "org1_private_subnet"
  }
}
##subnets org2
resource "aws_subnet" "org2_public_subnet" {
  vpc_id            = aws_vpc.org2_vpc.id
  cidr_block        = "172.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "org2_public_subnet"
  }

}
resource "aws_subnet" "org2_private_subnet" {
  vpc_id            = aws_vpc.org2_vpc.id
  cidr_block        = "172.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "org2_private_subnet"
  }
}

## eips
resource "aws_eip" "nat_eip" {
  vpc = true

}
resource "aws_eip" "org1_webserver" {
  instance = aws_instance.org1_webserver.id
  vpc      = true
  tags = {
    Name = "org1_webserver"
  }

}



## gatewayes

resource "aws_nat_gateway" "org1_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.org1_public_subnet.id
  tags = {
    Name = "org1_nat_gateway"
  }
}

resource "aws_internet_gateway" "org1_internet_gateway" {
  vpc_id = aws_vpc.org1_vpc.id
  tags = {
    Name = "org1_internet_gateway"
  }
}



##route tables
resource "aws_route_table" "org1_route_table" {
  vpc_id = aws_vpc.org1_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.org1_internet_gateway.id
  }
  tags = {
    Name = "org1_route_table"
  }
}
resource "aws_route_table" "org1_prive_route_table" {
  vpc_id = aws_vpc.org1_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.org1_nat_gateway.id
  }
  tags = {
    Name = "org1_prive_route_table"
  }
}
## associations because aperntly  its not automatic #learnt the hard way
resource "aws_route_table_association" "org1_association" {
  subnet_id      = aws_subnet.org1_public_subnet.id
  route_table_id = aws_route_table.org1_route_table.id
}

resource "aws_route_table_association" "org1_association_prive" {
  subnet_id      = aws_subnet.org1_private_subnet.id
  route_table_id = aws_route_table.org1_prive_route_table.id
}



## ACL
resource "aws_network_acl" "allowall" {
  vpc_id = aws_vpc.org1_vpc.id
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}



## SG
resource "aws_security_group" "allowall_org1" {
  name   = "allow all will fix later"
  vpc_id = aws_vpc.org1_vpc.id
  ingress {
    from_port   = 22
    to_port     = 100
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


# key pair
resource "aws_key_pair" "defualt" {
  key_name   = "Purple"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+O6x7paobDWt4cilQqqU3GiasCNX+eLJG2Ggaql0LVywT/Uh017XGJ2xuJZEjOqmjpSWLdV3uuQWXsfVgWN3Y2MbHOc5mWq1+OXUGA3mENnDndQG1mVdpx110ogh0zcrDNrdZERkvRb5TgvKxp9/UXD4uLp3o9qGM/o0tgfjtRsfM4Tzec4+OXZacMtDn1SaLi5IiFMTdryZw2Vh9SwzlmIYfRMI5uZsFtXN82eujsbazivsVAyGCk76wDfwCc32i2wGqqNtQonZ3qA4bC+NmR4oa1Se+1Jhv3dS4b9k1GBfXPmvn8vjbkhbJquQLiVOIwIGtaQWR+3hL/vz5jpl speed@speed-GE60-2PC"
}



## EC2
resource "aws_instance" "org1_webserver" {

  ami                    = "ami-038b3df3312ddf25d"
  instance_type          = var.instancetype
  key_name               = aws_key_pair.defualt.key_name
  vpc_security_group_ids = [aws_security_group.allowall_org1.id]
  subnet_id              = aws_subnet.org1_public_subnet.id
  tags = {
    Name = "org1_webserver"
  }
}
resource "aws_instance" "org1_back_server" {

  ami                    = "ami-038b3df3312ddf25d"
  instance_type          = var.instancetype
  key_name               = aws_key_pair.defualt.key_name
  vpc_security_group_ids = [aws_security_group.allowall_org1.id]
  subnet_id              = aws_subnet.org1_private_subnet.id
  tags = {
    Name = "org1_back_server"
  }
}


resource "aws_s3_bucket" "b" {
  bucket = "team-one-devops-sercure"
  # bucket will habve to be unique 
  tags = {
    Name        = "My bucket"
    Environment = "live"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}


#s3 end point
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.org1_vpc.id
  service_name = "com.amazonaws.us-east-1.s3"
  policy       = <<POLICY
{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
}


#associat the end point 
resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  route_table_id  = aws_route_table.org1_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

