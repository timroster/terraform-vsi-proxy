# Squid Proxy Terraform module

## Module overview

### Description

This module will create a VSI with a HTTP/HTTPS proxy (based on squid) installed. The module depends on a pre-existing VPC and subnet to use for the deployment. After the VSI is created, it will be customized to accept traffic to proxy from a specific subnet set in the `allow_network` variable. The module defaults this to be the network `10.0.0.0/8` which may be acceptable for general IBM Cloud VPC use. If the deployment subnet does not have a public gateway, set the `create_public_ip` variable to *true* in order to allow the proxy to reach the Internet.

When deployed in a VPC with multiple subnets/zones, this module will create a VM with a squid proxy for each zone and then configure a VPC Load Balancer to front-end the proxy instances. When the LB is created, instead of a single IP address of the proxy, the hostname for the LB will be provided in the module output.

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
  ssh_key_id        = module.vpcssh.id
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
