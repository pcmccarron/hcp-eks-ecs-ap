# HCP Consul Admin Partitions Demo

This demo builds an HCP Consul cluster, EKS Cluster and ECS Cluster. Each cluster runs in a separate admin partition and the API Gateway deploys in the EKS cluster.

For demo purposes only, does not support production workloads.

To get started make sure you set the following environment variables or save them in a `values.tfvars`

```
export AWS_ACCESS_KEY_ID = <Your AWS Access Key>
export AWS_SECRET_ACCESS_KEY = <Your AWS Secret Key>
export HCP_CLIENT_ID = <Your HCP Client ID>
export HCP_CLIENT_SECRET = <Your HCP Client Secret>
```