variable "resource_group_name" {
  type        = string
  description = "The name of the IBM Cloud resource group where the VPC has been provisioned."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster will be/has been installed."
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
}

variable "vpc_name" {
  type        = string
  description = "The name of the vpc instance"
}

variable "label" {
  type        = string
  description = "The label for the server instance"
  default     = "server"
}

variable "vpc_subnet_count" {
  type        = number
  description = "Number of vpc subnets"
}

variable "vpc_subnets" {
  type = list(object({
    label = string
    id    = string
    zone  = string
  }))
  description = "List of subnets with labels"
  default = []
}

variable "ssh_key_name" {
  type        = string
  description = "Name of existing SSH key ID to inject into the virtual server instance"
}

variable "allow_ssh_from" {
  type        = string
  description = "An IP address, a CIDR block, or a single security group identifier to allow incoming SSH connection to the virtual server"
  default     = "10.0.0.0/8"
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Tags that should be added to the instance"
}
