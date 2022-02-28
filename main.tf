
locals {
  subnets             = data.ibm_is_subnet.vpc_subnet
  tags                = tolist(setsubtract(concat(var.tags, ["proxy"]), [""]))
  name                = "${replace(var.vpc_name, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${var.label}"
  base_security_group = var.base_security_group != null ? var.base_security_group : data.ibm_is_vpc.vpc.default_security_group
  proxy-host          = var.vpc_subnet_count == 1 ? module.vsi-instance.private_ips[0] : ibm_is_lb.proxy-alb[0].hostname
  proxy-port          = "3128"
}

resource "null_resource" "print-names" {
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
  provisioner "local-exec" {
    command = "echo 'Resource group id: ${var.resource_group_id}'"
  }
}

# get the information about the existing vpc instance
data "ibm_is_vpc" "vpc" {
  depends_on = [null_resource.print-names]

  name = var.vpc_name
}

data "ibm_is_subnet" "vpc_subnet" {
  count = var.vpc_subnet_count

  identifier = var.vpc_subnets[count.index].id
}

module "vsi-instance" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-vsi.git?ref=v1.11.0"

  resource_group_id      = var.resource_group_id
  region                 = var.region
  ibmcloud_api_key       = var.ibmcloud_api_key
  vpc_name               = var.vpc_name
  vpc_subnet_count       = var.vpc_subnet_count
  vpc_subnets            = var.vpc_subnets
  image_name             = var.image_name
  profile_name           = var.profile_name
  ssh_key_id             = var.ssh_key_id
  kms_key_crn            = var.kms_key_crn
  kms_enabled            = var.kms_enabled
  init_script            = data.cloudinit_config.this.rendered
  create_public_ip       = var.create_public_ip
  allow_ssh_from         = var.allow_ssh_from
  tags                   = local.tags
  security_group_rules   = var.security_group_rules
  label                  = var.label
  allow_deprecated_image = var.allow_deprecated_image
  base_security_group    = var.base_security_group
  acl_rules              = var.acl_rules
  target_network_range   = var.target_network_range
}

data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/${var.init_script}", {
      "allow_network" = var.allow_network
    })
  }
}
resource "ibm_is_lb" "proxy-alb" {
  count = var.vpc_subnet_count == 1 ? 0 : 1

  name            = "${local.name}-alb"
  subnets         = var.vpc_subnets[*].id
  resource_group  = var.resource_group_id
  type            = "private"
  security_groups = [local.base_security_group]
  tags            = local.tags
}

resource "ibm_is_lb_pool" "squid_pool" {
  count = var.vpc_subnet_count == 1 ? 0 : 1

  name                = "${local.name}-alb-pool"
  lb                  = ibm_is_lb.proxy-alb[0].id
  algorithm           = "round_robin"
  protocol            = "tcp"
  health_delay        = 60
  health_retries      = 5
  health_timeout      = 30
  health_type         = "tcp"
  health_monitor_port = local.proxy-port
}

resource "ibm_is_lb_pool_member" "squid_lb_mem" {
  count = var.vpc_subnet_count == 1 ? 0 : var.vpc_subnet_count

  lb             = ibm_is_lb.proxy-alb[0].id
  pool           = ibm_is_lb_pool.squid_pool[0].id
  port           = local.proxy-port
  target_address = module.vsi-instance.private_ips[count.index]
}

resource "ibm_is_lb_listener" "squid_lb_listener" {
  count = var.vpc_subnet_count == 1 ? 0 : 1

  lb           = ibm_is_lb.proxy-alb[0].id
  default_pool = ibm_is_lb_pool.squid_pool[0].id
  port         = local.proxy-port
  protocol     = "tcp"
}

resource "ibm_is_security_group_rule" "maintenance_ssh_inbound" {
  group     = local.base_security_group
  direction = "inbound"
  remote    = module.vsi-instance.security_group_id
  tcp {
    port_min = 22
    port_max = 22
  }
}