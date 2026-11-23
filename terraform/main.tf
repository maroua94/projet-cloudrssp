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

# Image Ubuntu 22.04 officielle (Canonical), la plus recente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_vpc" "default" {
  default = true
}

locals {
  ssh_actif = var.ssh_public_key != "" && length(var.allowed_cidrs) > 0
}

# Pare-feu : seul le site (HTTP, port 80) est public.
# Jenkins, Grafana, Prometheus et Wazuh ne tournent pas ici : ils restent en local.
resource "aws_security_group" "plateforme" {
  name_prefix = "plateforme-devsecops-"
  description = "Site vitrine public, SSH restreint"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Site vitrine public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = local.ssh_actif ? [22] : []
    content {
      description = "SSH administration"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidrs
    }
  }

  egress {
    description = "Sortie libre (mises a jour, Docker, GitHub)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_key_pair" "admin" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "plateforme-devsecops"
  public_key = var.ssh_public_key
}

resource "aws_instance" "plateforme" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.plateforme.id]
  key_name               = var.ssh_public_key != "" ? aws_key_pair.admin[0].key_name : null

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    repo_url = var.repo_url
  })
  user_data_replace_on_change = true

  # IMDSv2 obligatoire
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size = var.disk_gb
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "plateforme-devsecops"
  }
}

# Adresse IP fixe : elle ne change pas quand on arrete puis redemarre la machine
resource "aws_eip" "plateforme" {
  domain   = "vpc"
  instance = aws_instance.plateforme.id
}
