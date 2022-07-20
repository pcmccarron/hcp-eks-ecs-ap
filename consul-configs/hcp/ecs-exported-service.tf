resource "consul_config_entry" "export_public_api_to_eks" {
  kind      = "exported-services"
  name      = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
  partition = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
  namespace = var.ecs_ap_globals.namespace_identifiers.global
  config_json = jsonencode({
    Services = [
      {
        Name      = "*"
        Namespace = "*"
        Consumers = [
          {
            Partition = "eks"
          }
        ]
      }
    ]
  })
  depends_on = [aws_ecs_service.private_services]
}