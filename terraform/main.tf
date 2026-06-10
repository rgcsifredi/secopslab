terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "secops-lab-vpc" }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false   # Checkov will flag true — good lesson!
  tags = { Name = "secops-lab-public" }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab_vpc.id
}

# Security group — restrictive by default
resource "aws_security_group" "ec2_sg" {
  name   = "secops-lab-sg"
  vpc_id = aws_vpc.lab_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # No ingress — Checkov will check for 0.0.0.0/0 ingress rules
}

# EC2 instance
resource "aws_instance" "lab_ec2" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  metadata_options {
    http_tokens = "required"   # IMDSv2 — Checkov requires this
  }

  root_block_device {
    encrypted = true           # Checkov will flag unencrypted volumes
  }

  tags = { Name = "secops-lab-ec2" }
}
