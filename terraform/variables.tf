variable "region" {
  description = "Region AWS (Stockholm)"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "Type de machine : 8 Gio de memoire, eligible au plan gratuit"
  type        = string
  default     = "m7i-flex.large"
}

variable "disk_gb" {
  description = "Taille du disque en Go"
  type        = number
  default     = 40
}

variable "allowed_cidrs" {
  description = "Adresses IP autorisees a ouvrir les outils, au format 1.2.3.4/32 (toi + ton equipe)"
  type        = list(string)

  validation {
    condition     = length(var.allowed_cidrs) > 0 && alltrue([for c in var.allowed_cidrs : can(cidrnetmask(c)) && c != "0.0.0.0/0"])
    error_message = "Donne au moins une adresse au format 1.2.3.4/32, jamais 0.0.0.0/0."
  }
}

variable "ssh_public_key" {
  description = "Cle publique SSH pour administrer la machine (laisser vide = pas de SSH)"
  type        = string
  default     = ""
}

variable "grafana_admin_password" {
  description = "Mot de passe administrateur de Grafana (12 caracteres minimum, sans apostrophe)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 12 && !can(regex("'", var.grafana_admin_password))
    error_message = "12 caracteres minimum et pas d'apostrophe."
  }
}

variable "wazuh_ouvert" {
  description = "Ouvrir le port 443 (Wazuh) ? A mettre a true seulement apres avoir change les mots de passe par defaut de Wazuh"
  type        = bool
  default     = false
}

variable "repo_url" {
  description = "Depot GitHub du projet"
  type        = string
  default     = "https://github.com/maroua94/projet-cloudrssp.git"
}
