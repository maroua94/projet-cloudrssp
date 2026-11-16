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
  # Ports des outils : Portail 80, Jenkins 8080, Grafana 3000, Prometheus 9090, Application 5000
  ports_outils = [80, 8080, 3000, 9090, 5000]
  ports_ouverts = concat(
    local.ports_outils,
    var.wazuh_ouvert ? [443] : [],
    var.ssh_public_key != "" ? [22] : []
  )
}

# Pare-feu : uniquement les adresses IP de l'equipe. Les ports internes de Wazuh
# (9200, 55000, 1514, 1515) et Node Exporter (9100) ne sont jamais ouverts.
resource "aws_security_group" "plateforme" {
  name_prefix = "plateforme-devsecops-"
  description = "Outils ouverts aux IP de l equipe uniquement"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = toset(local.ports_ouverts)
    content {
      description = "Acces equipe port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
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
    repo_url         = var.repo_url
    grafana_password = var.grafana_admin_password
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
