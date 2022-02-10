
locals {
  subnets             = data.ibm_is_subnet.vpc_subnet
  tags                = tolist(setsubtract(concat(var.tags, ["proxy"]), [""]))
  name                = "${replace(var.vpc_name, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${var.label}"
  base_security_group = var.base_security_group != null ? var.base_security_group : data.ibm_is_vpc.vpc.default_security_group
}

resource null_resource print-names {
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
  provisioner "local-exec" {
    command = "echo 'Resource group id: ${var.resource_group_id}'"
  }
}

# get the information about the existing vpc instance
data ibm_is_vpc vpc {
  depends_on = [null_resource.print-names]

  name           = var.vpc_name
}

data ibm_is_subnet vpc_subnet {
  count = var.vpc_subnet_count

  identifier = var.vpc_subnets[count.index].id
}

module "vsi-instance" {
  source = "github.com/timroster/terraform-ibm-vpc-vsi"

  resource_group_id    = var.resource_group_id
  region               = var.region
  ibmcloud_api_key     = var.ibmcloud_api_key
  vpc_name             = var.vpc_name
  vpc_subnet_count     = var.vpc_subnet_count
  vpc_subnets          = var.vpc_subnets
  image_name           = var.image_name
  profile_name         = var.profile_name
  ssh_key_id           = var.ssh_key_id
  kms_key_crn          = var.kms_key_crn
  kms_enabled          = var.kms_enabled
  init_script          = data.cloudinit_config.this.rendered
  create_public_ip     = var.create_public_ip
  allow_ssh_from       = var.allow_ssh_from
  tags                 = local.tags
  security_group_rules = var.security_group_rules
  label                = var.label
  allow_deprecated_image = var.allow_deprecated_image
  base_security_group  = var.base_security_group
  acl_rules            = var.acl_rules
  target_network_range = var.target_network_range
}

data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/${var.init_script}", {
      "allow_network"  = var.allow_network
    })
  }
}

resource ibm_is_security_group_rule ssh_to_host_in_maintenance {
  group     = module.vsi-instance.security_group_id
  direction = "outbound"
  remote    = local.base_security_group
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource ibm_is_security_group_rule maintenance_ssh_inbound {
  group     = local.base_security_group
  direction = "inbound"
  remote    = module.vsi-instance.security_group_id
  tcp {
    port_min = 22
    port_max = 22
  }
}

locals {
  proxy-config = templatefile("${path.module}/templates/_template_proxy-config.yaml", {
    "proxy_ip" = module.vsi-instance.private_ips[0]
  })
  crio-config = templatefile("${path.module}/templates/_template_setcrioproxy.yaml", {
    "proxy_ip" = module.vsi-instance.private_ips[0],
    "cluster_local" = var.allow_network
  })
}