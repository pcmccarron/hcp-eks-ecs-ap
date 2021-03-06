resource "hcp_consul_cluster" "main" {
  cluster_id         = var.cluster_id
  hvn_id             = hcp_hvn.main.hvn_id
  public_endpoint    = true
  tier               = var.consul_tier
  min_consul_version = var.min_consul_version
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}