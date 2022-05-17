resource "consul_config_entry" "postgres_intentions_to_product_api" {
  kind      = "service-intentions"
  name      = local.tnames.postgres
  partition = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
        Name       = local.tnames.product-api
        Namespace  = var.ecs_ap_globals.namespace_identifiers.global
        Partition  = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
      }
    ],
  })
}