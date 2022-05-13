variable "cluster_id" {
  type        = string
  description = "The name of your HCP Consul cluster"
  default     = "consul"
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
    },
    consul_enterprise_image = {
      enterprise_latest   = "public.ecr.aws/hashicorp/consul-enterprise:1.12.0-ent"
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

variable "iam_service_principals" {
  type        = map(string)
  description = "Names of the Services Principals this tutorial needs"
  default = {
    ecs_tasks = "ecs-tasks.amazonaws.com"
    ecs       = "ecs.amazonaws.com"
  }
}

variable "iam_role_name" {
  type        = string
  description = "Base name of the IAM role to create in this tutorial"
  default     = "demo"
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

variable "hashicups_settings_private" {
  type        = any
  description = "Settings for hashicups services deployed to default partition"
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
          destinationPartition = "default"
        },
      ],
      volumes = []
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
  ]
}

variable "security_group_ids" {
  type        = list(string)
  description = "A list of security group IDs which should allow inbound Consul client traffic. If no security groups are provided, one will be generated for use."
  default     = []
}