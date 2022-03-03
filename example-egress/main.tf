terraform {
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.17"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 0.15"
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

data "ibm_is_ssh_key" "existing" {
  name = var.ssh_key_name
}

module "resource_group" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-resource-group.git"

  resource_group_name = var.resource_group_name
  provision           = false
}


module "gateways" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-gateways.git"

  resource_group_id = module.resource_group.id
  region            = var.region
  vpc_name          = var.vpc_name
  provision         = true
}

module "egress_subnet" {
  source = "cloud-native-toolkit/vpc-subnets/ibm"

  resource_group_name = var.resource_group_name
  vpc_name            = var.vpc_name
  gateways            = module.gateways.gateways
  _count              = var.vpc_subnet_count
  region              = var.region
  label               = "egress"
  provision           = true
  # acl_rules = [{
  #   name        = "inbound-ssh"
  #   action      = "allow"
  #   direction   = "inbound"
  #   source      = "0.0.0.0/0"
  #   destination = "0.0.0.0/0"
  # }]
}

module "proxy" {
  source = "../"

  resource_group_name = var.resource_group_name
  region              = var.region
  ibmcloud_api_key    = var.ibmcloud_api_key
  ssh_key_id          = data.ibm_is_ssh_key.existing.id
  vpc_name            = var.vpc_name
  vpc_subnet_count    = var.vpc_subnet_count
  vpc_subnets         = module.egress_subnet.subnets
}

output "proxy_endpoint" {
  value = module.proxy.proxy_endpoint
}
