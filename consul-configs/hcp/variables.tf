variable "cluster_id" {
  type        = string
  description = "The name of your HCP Consul cluster"
  default     = "consul"
}

variable "min_consul_version" {
  type        = string
  description = "The version of Consul to use"
  default     = "1.12.2"
}

variable "vpc_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

variable "hvn_region" {
  type        = string
  description = "The HCP region to create resources in"
  default     = "us-west-2"
}

variable "hvn_id" {
  type        = string
  description = "The name of your HCP HVN"
  default     = "demo"
}

variable "hvn_cidr_block" {
  type        = string
  description = "The CIDR range to create the HCP HVN with"
  default     = "172.25.32.0/20"
}

variable "consul_tier" {
  type        = string
  description = "The HCP Consul tier to use when creating a Consul cluster"
  default     = "development"
}

variable "hcp_client_id" {
  description = "HCP Client ID."
  type        = string
  sensitive   = true
}

variable "hcp_client_secret" {
  description = "HCP Client Secret."
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key."
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  description = "AWS Access Key."
  type        = string
  sensitive   = true
}

resource "random_id" "random" {
  byte_length = 2
}

variable "ecs_ap_globals" {
  default = {
    global_prefix = "ap",
    acl_controller = {
      prefix      = "ap"
      logs_prefix = "acl"
    },
    namespace_identifiers = {
      global = "default"
    },
    admin_partitions_identifiers = {
      partition-one = "ecs"
    },
    enable_admin_partitions = {
      enabled     = true
      not_enabled = false
    },
    cloudwatch_config = {
      log_driver    = "awslogs"
      create_groups = "true"
    },
    base_cloudwatch_path = {
      hashicups = "/hashicups/ecs"
    },
    task_families = {
      postgres    = "postgres"
      product-api = "product-api"
      public-api  = "public-api"
      payments    = "payments"
    },
    consul_enterprise_image = {
      enterprise_latest   = "public.ecr.aws/hashicorp/consul-enterprise:1.12.2-ent"
    },
    ecs_clusters = {
      one = {
        name = "ecs-cluster"
      }
    },
    ecs_capacity_providers = ["FARGATE"]
  }
}

variable "region" {
  type        = string
  description = "AWS region."
  default     = "us-west-2"
}


variable "cluster_cidrs" {
  type        = any
  description = "VPC settings for this tutorial"
  default = {
    ecs_cluster = {
      name            = "ecs_cluster"
      cidr_block      = "10.0.0.0/16"
      private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    },
  }
}

variable "iam_role_name" {
  type        = string
  description = "Base name of the IAM role to create in this tutorial"
  default     = "hashicups"
}


variable "iam_service_principals" {
  type        = map(string)
  description = "Names of the Services Principals this tutorial needs"
  default = {
    ecs_tasks = "ecs-tasks.amazonaws.com"
    ecs       = "ecs.amazonaws.com"
  }
}

variable "iam_effect" {
  type        = map(string)
  description = "Allow or Deny for IAM policies"
  default = {
    allow = "Allow"
    deny  = "Deny"
  }
}

variable "iam_action_type" {
  type        = map(string)
  description = "Actions required for IAM roles in this tutorial"
  default = {
    assume_role = "sts:AssumeRole"
  }
}

variable "iam_actions_allow" {
  type        = map(any)
  description = "What resources an IAM role is accessing in this tutorial"
  default = {
    secrets_manager_get = ["secretsmanager:GetSecretValue"]
    logging_create_and_put = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
    "logs:PutLogEvent"]
    elastic_load_balancer = ["elasticloadbalancing:*"]

  }
}

variable "iam_logs_actions_allow" {
  default = [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvent"
  ]
}

variable "hashicups_settings_private" {
  type        = any
  description = "Settings for hashicups services deployed to ecs partition"
  default = [
    {
      name  = "product-api"
      image = "hashicorpdemoapp/product-api:v0.0.21"
      environment = [{
        name  = "DB_CONNECTION"
        value = "host=localhost port=5432 user=postgres password=password dbname=products sslmode=disable"
        },
        {
          name  = "METRICS_ADDRESS"
          value = ":9103"
        },
        {
          name  = "BIND_ADDRESS"
          value = ":9090"
      }]
      portMappings = [{
        protocol      = "tcp"
        containerPort = 9090
        hostPort      = 9090
      }]
      upstreams = [
        {

          destinationName      = "postgres"
          localBindPort        = 5432
          destinationNamespace = "default"
          destinationPartition = "ecs"
        },
      ],
      volumes = []
    },
    {
      name  = "payments"
      image = "hashicorpdemoapp/payments:v0.0.16"
      portMappings = [{
        protocol      = "tcp"
        containerPort = 1800
        hostPort      = 1800
      }]
      upstreams   = []
      environment = []
    },
     {
      name  = "postgres"
      image = "hashicorpdemoapp/product-api-db:v0.0.21"
      environment = [{
        name  = "POSTGRES_DB"
        value = "products"
        },
        {
          name  = "POSTGRES_USER"
          value = "postgres"
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = "password"
      }]
      portMappings = [{
        protocol      = "tcp"
        containerPort = 5432
        hostPort      = 5432
      }]
      upstreams = []
    },
    {
      name  = "public-api"
      image = "hashicorpdemoapp/public-api:v0.0.6"
      environment = [{
        name  = "BIND_ADDRESS"
        value = ":8081"
        },
        {
          name  = "PRODUCT_API_URI"
          value = "http://localhost:9090"
        },
        {
          name  = "PAYMENT_API_URI"
          value = "http://localhost:1800"
      }]
      portMappings = [{
        protocol      = "tcp"
        containerPort = 8081
        hostPort      = 8081
      }]
      upstreams = [{
        destinationName      = "product-api"
        destinationNamespace = "default"
        destinationPartition = "ecs"
        localBindPort        = 9090
        },
        {
          destinationName      = "payments"
          destinationNamespace = "default"
          destinationPartition = "ecs"
          localBindPort        = 1800
      }]
    },
  ]
}

variable "security_group_ids" {
  type        = list(string)
  description = "A list of security group IDs which should allow inbound Consul client traffic. If no security groups are provided, one will be generated for use."
  default     = []
}

variable "target_group_settings" {
  type        = any
  description = "Load Balancer target groups for HashiCups services exposed to internet"
  default = {
    elb = {
      services = [
        {
          name                 = "public-api"
          service_type         = "http"
          protocol             = "HTTP"
          target_group_type    = "ip"
          port                 = "8081"
          deregistration_delay = 30
          health = {
            healthy_threshold   = 2
            unhealthy_threshold = 2
            interval            = 30
            timeout             = 29
            path                = "/"
            port                = "8081"
          },
        },
      ]
    }
  }
}

variable "enable_mesh_gateway_wan_federation" {
  description = "Controls whether or not WAN federation via mesh gateways is enabled. Default is false."
  type        = bool
  default     = false
}

variable "wan_address" {
  description = "The WAN address of the mesh gateway."
  type        = string
  default     = ""
}

variable "wan_port" {
  description = "The WAN port of the mesh gateway. Default is 8443"
  type        = number
  default     = 8443
}

variable "consul_ecs_image" {
  description = "Consul ECS image to use in all tasks."
  type        = string
  default     = "public.ecr.aws/hashicorp/consul-ecs:0.5.0"
}