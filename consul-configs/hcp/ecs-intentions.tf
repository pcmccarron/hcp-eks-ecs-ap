resource "consul_config_entry" "frontend_to_public_api_intention" {
  kind      = "service-intentions"
  name      = local.tnames.public-api
  partition = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
        Name       = "nginx"
        Namespace  = "default"
        Partition  = "eks"
      }
    ],
  })
}
