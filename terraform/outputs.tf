output "public_ip" {
  description = "Adresse IP publique de la machine"
  value       = aws_instance.portail.public_ip
}

output "url_portail" {
  description = "Adresse du portail (patienter 2 à 3 minutes après la création)"
  value       = "http://${aws_instance.portail.public_ip}"
}
