data "aws_ecs_task_definition" "private_tasks" {
  for_each        = toset(local.tasks.private)
  task_definition = each.value

  depends_on = [module.hashicups-tasks-private]
}

data "consul_services" "all" {
  query_options {
    namespace = local.namespace
  }
  depends_on = [aws_ecs_service.private_services]
}

data "consul_service" "each" {
  for_each = toset(concat(local.tasks.private))
  name = each.key
  query_options {
  wait_time = "1m"
  }
}

locals {
  tnames = {
    postgres = data.consul_service.each["postgres"].name
    product-api = data.consul_service.each["product-api"].name
  }
}

