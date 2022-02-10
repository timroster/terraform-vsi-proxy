output ids {
  description = "The instance ids"
  value       = module.vsi-instance.ids
}

output names {
  description = "The instance names"
  value       = module.vsi-instance.names
}

output vpc_name {
  value = data.ibm_is_vpc.vpc.name
}

output count {
  value = var.vpc_subnet_count
}

output instance_count {
  value = var.vpc_subnet_count
}

output public_ips {
  value = module.vsi-instance.public_ips
}

output private_ips {
  value = module.vsi-instance.private_ips
}

output network_interface_ids {
  value = module.vsi-instance.network_interface_ids
}

output "security_group_id" {
  description = "The id of the security group that was created"
  value       = module.vsi-instance.security_group_id
}

output "security_group" {
  description = "The security group that was created"
  value       = module.vsi-instance.security_group
}

output "maintenance_security_group_id" {
  description = "The id of the security group that was used"
  value       = local.base_security_group
}

output "proxy-config-yaml" {
  description = "apply to cluster to enable system use of proxy"
  value = local.proxy-config
}

output "setcrioproxy-yaml" {
  description = "apply to cluster to enable system use of proxy"
  value = local.crio-config
}
