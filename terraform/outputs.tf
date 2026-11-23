output "public_ip" {
  value = aws_eip.plateforme.public_ip
}

output "url_site" {
  description = "Adresse publique du site vitrine"
  value       = "http://${aws_eip.plateforme.public_ip}"
}

output "ssh" {
  value = local.ssh_actif ? "ssh -i ~/.ssh/aws_plateforme ubuntu@${aws_eip.plateforme.public_ip}" : "SSH desactive"
}
