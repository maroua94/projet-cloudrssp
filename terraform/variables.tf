variable "region" {
  description = "Région AWS"
  type        = string
  default     = "eu-north-1" # Stockholm
}

variable "instance_type" {
  description = "Type de machine (petit, couvert par le plan gratuit)"
  type        = string
  default     = "t3.micro"
}

variable "admin_cidr" {
  description = "Mon adresse IP publique au format x.x.x.x/32 pour autoriser SSH. Vide = SSH fermé."
  type        = string
  default     = ""
}
