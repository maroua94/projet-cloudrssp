output "public_ip" {
  value = aws_eip.plateforme.public_ip
}

output "urls" {
  description = "Adresses des outils (accessibles depuis les IP autorisees)"
  value = {
    portail    = "http://${aws_eip.plateforme.public_ip}"
    jenkins    = "http://${aws_eip.plateforme.public_ip}:8080"
    grafana    = "http://${aws_eip.plateforme.public_ip}:3000"
    prometheus = "http://${aws_eip.plateforme.public_ip}:9090"
    application = "http://${aws_eip.plateforme.public_ip}:5000"
    wazuh      = var.wazuh_ouvert ? "https://${aws_eip.plateforme.public_ip}" : "ferme (wazuh_ouvert = false)"
  }
}

output "ssh" {
  value = var.ssh_public_key != "" ? "ssh ubuntu@${aws_eip.plateforme.public_ip}" : "SSH desactive"
}
