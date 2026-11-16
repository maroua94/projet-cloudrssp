terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Projet           = "plateforme-devsecops"
      GereParTerraform = "oui"
    }
  }
}

# Image Ubuntu 22.04 officielle (Canonical), la plus récente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

# Pare-feu : seul le portail (HTTP) est public. Jenkins, Grafana et Wazuh ne sont PAS exposés.
resource "aws_security_group" "portail" {
  name_prefix = "portail-devsecops-"
  description = "Portail web public, SSH restreint"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP public (portail)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH uniquement si une adresse d'administration est fournie
  dynamic "ingress" {
    for_each = var.admin_cidr == "" ? [] : [var.admin_cidr]
    content {
      description = "SSH depuis mon adresse uniquement"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Sortie libre (mises à jour, Docker, GitHub)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "portail" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.portail.id]

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  # IMDSv2 obligatoire (protection contre le vol d'identifiants)
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 12
    encrypted   = true
  }

  tags = {
    Name = "portail-devsecops"
  }
}
