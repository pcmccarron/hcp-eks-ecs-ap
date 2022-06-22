global:
  enabled: false
  name: consul-eks
  datacenter: ${datacenter}
  image: "hashicorp/consul-enterprise:${consul_version}-ent"
  enableConsulNamespaces: true
  adminPartitions:
    enabled: true
    name: "eks"
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: ${cluster_id}-hcp
      secretKey: bootstrapToken
  tls:
    enabled: true
    enableAutoEncrypt: true
    caCert:
      secretName: ${cluster_id}-hcp
      secretKey: caCert
  gossipEncryption:
    secretName: ${cluster_id}-hcp
    secretKey: gossipEncryptionKey

externalServers:
  enabled: true
  hosts: ${consul_hosts}
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${k8s_api_endpoint}

server:
  enabled: false

client:
  enabled: true
  join: ${consul_hosts}
  nodeMeta:
    terraform-module: "hcp-eks-client"

connectInject:
  enabled: true
  transparentProxy:
    defaultEnabled: true
  consulNamespaces:
    mirroringK8s: true

controller:
  enabled: true

apiGateway:
  enabled: true
  image: "hashicorp/consul-api-gateway:0.3.0"
  managedGatewayClass:
    serviceType: LoadBalancer

meshGateway:
  enabled: true
  replicas: 1

dns: 
  enabled: true
  enableRedirection: true