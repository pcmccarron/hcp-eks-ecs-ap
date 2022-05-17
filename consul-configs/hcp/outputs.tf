output "outputs_not_sensitive" {
  value = {
    consul_ui_address = hcp_consul_cluster.main.consul_public_endpoint_url
    hashicups_url = "http://${aws_lb.frontend_lb.dns_name}"
  }
}
