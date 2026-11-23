variable "region" {
  description = "Region AWS (Stockholm)"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "Petite machine suffisante pour le portail, eligible au plan gratuit"
  type        = string
  default     = "t3.micro"
}

variable "disk_gb" {
  description = "Taille du disque en Go"
  type        = number
  default     = 12
}

variable "allowed_cidrs" {
  description = "Adresses IP autorisees en SSH (administration uniquement). Le site, lui, est public."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.allowed_cidrs : can(cidrnetmask(c)) && c != "0.0.0.0/0"])
    error_message = "Format 1.2.3.4/32, jamais 0.0.0.0/0."
  }
}

variable "ssh_public_key" {
  description = "Cle publique SSH pour administrer la machine (laisser vide = pas de SSH)"
  type        = string
  default     = ""
}

variable "repo_url" {
  description = "Depot GitHub du projet"
  type        = string
  default     = "https://github.com/maroua94/projet-cloudrssp.git"
}
