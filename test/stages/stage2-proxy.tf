module "proxy" {
  #source = "../.."
  source = "./module"

  resource_group_name    = module.resource_group.name
  region                 = var.region
  ibmcloud_api_key       = var.ibmcloud_api_key
  vpc_name               = module.vpc.name
  vpc_subnet_count       = module.subnets.count
  vpc_subnets            = module.subnets.subnets
  ssh_key_id             = module.vpcssh.id
  allow_deprecated_image = false
  create_public_ip       = true
  allow_ssh_from         = "0.0.0.0/0"
  acl_rules = [{
    name        = "outbound-all"
    action      = "allow"
    direction   = "outbound"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
  }]
}
