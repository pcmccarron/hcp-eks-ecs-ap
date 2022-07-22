resource "consul_config_entry" "export_public_api_to_eks" {
  kind      = "exported-services"
  name      = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
  partition = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
  namespace = "default"
  config_json = jsonencode({
    Services = [
      {
        Name      = "public-api"
        Namespace = "default"
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