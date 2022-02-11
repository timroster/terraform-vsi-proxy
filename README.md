# Squid Proxy Terraform module

## Module overview

### Description

This module will create a VSI with a HTTP/HTTPS proxy (based on squid) installed. The module depends on a pre-existing VPC and subnet to use for the deployment. After the VSI is created, it will be customized to accept traffic to proxy from a specific subnet set in the `allow_network` variable. The module defaults this to be the network `10.0.0.0/8` which may be acceptable for general IBM Cloud VPC use. If the deployment subnet does not have a public gateway, set the `create_public_ip` variable to *true* in order to allow the proxy to reach the Internet.

OpenShift clusters need to be customized in order to use the HTTP/HTTPS proxy for outbound traffic. This module includes in the output file content as `proxy-config-yaml` that can be applied to set the OpenShift cluster proxy resource. For Red Hat OpenShift on IBM Cloud, there is also a daemonset file `setcrioproxy-yaml` output from the module than needs to be applied to the cluster to update each worker container runtime. After the daemonset is applied, workers need to be rebooted for the update to take effect. The script `example/set-cluster-proxy.sh` can be used to apply the sample files and carry out a worker rolling restart.

**Note:** This module follows the Terraform conventions regarding how provider configuration is defined within the Terraform template and passed into the module - <https://www.terraform.io/docs/language/modules/develop/providers.html>. The default provider configuration flows through to the module. If different configuration is required for a module, it can be explicitly passed in the `providers` block of the module - <https://www.terraform.io/docs/language/modules/develop/providers.html#passing-providers-explicitly>.

### Software dependencies

The module depends on the following software components:

#### Command-line tools

- terraform >= v0.15

#### Terraform providers

- IBM Cloud provider >= 1.17

### Module dependencies

This module makes use of the output from other modules:

- VPC - github.com/cloud-native-toolkit/terraform-ibm-vpc.git
- Subnet - github.com/cloud-native-toolkit/terraform-ibm-vpc.git
- KMS - github.com/cloud-native-toolkit/terraform-ibm-kms.git

### Example usage

```hcl-terraform
module "proxy" {
  source = "github.com/cloud-native-toolkit/terraform-vsi-proxy.git"

  resource_group_id = var.resource_group_id
  region            = var.region
  ibmcloud_api_key  = var.ibmcloud_api_key
  ssh_key_id        = module.vpc-ssh.id
  vpc_name          = module.vpc.name
  subnet_count      = module.dev_subnet.subnet_count
  vpc_subnets       = module.dev_subnet.vpc_subnets
}

resource "local_file" "proxy-config" {
  filename = "proxy-config.yaml"
  content  = module.proxy.proxy-config-yaml
}

resource "local_file" "setcrioproxy" {
  filename = "setcrioproxy.yaml"
  content  = module.proxy.setcrioproxy-yaml
}
```
