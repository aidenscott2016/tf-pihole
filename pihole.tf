terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-2"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "pihole"
  cidr = "10.0.0.0/16"

  azs            = ["eu-west-2a"]
  public_subnets = ["10.0.101.0/24"]
}



data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Deep Learning AMI (Amazon Linux 2)*"] #docker preinstalled

  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "pihole" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  # key_name                    = aws_key_pair.bastard
  key_name                    = "bastard-key"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.sgpihole.id]
  associate_public_ip_address = true
  user_data                   = file("./start_pihole.sh")

  tags = {
    Name = "pihole-outer"
  }
}



# resource "aws_key_pair" "bastard" {
#   public-key = ""
# }

resource "aws_security_group" "sgpihole" {
  name        = "pihole-sg"
  description = "Allow incoming HTTP connections & SSH access"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id


  tags = {
    Name = "pihole sg"
  }
}


output "server-ip" {
  value = aws_instance.pihole.public_ip
}
