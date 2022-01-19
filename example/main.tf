terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      version = ">= 1.17"
    }
  }
  required_version = ">= 0.15"
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region = var.region
}

data "ibm_is_ssh_key" "existing" {
  name = var.ssh_key_name
}

module "proxy" {
  source = "../"

  resource_group_id   = var.resource_group_id
  region              = var.region
  ibmcloud_api_key    = var.ibmcloud_api_key
  ssh_key_id          = data.ibm_is_ssh_key.existing.id
  vpc_name            = var.vpc_name
  vpc_subnet_count    = var.vpc_subnet_count
  vpc_subnets         = var.vpc_subnets
}

output "private_ip_address" {
  value = module.proxy.private_ips
}