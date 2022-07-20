resource "consul_config_entry" "public-api" {
  kind = "service-defaults"
  name = data.consul_service.each["public-api"].name

  config_json = jsonencode({
    Protocol = local.consul_service_defaults_protocols.tcp
     MeshGateway = {
            Mode = "local"
        }
  })
}