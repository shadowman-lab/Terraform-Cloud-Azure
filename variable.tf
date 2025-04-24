variable "rhel_version" {
  description = "RHEL Version"
  default     = "RHEL9"
}

variable "azure_user" {
  description = "VM Username"
}

variable "azure_password" {
  description = "VM Password"
}

variable "product_map" {
  type = map(string)
  default = {
    "RHEL7" = "rhel-lvm79"
    "RHEL8" = "rhel-lvm810"
    "RHEL9" = "rhel-lvm95"
  }
}

variable "instance_name_convention" {
  description = "VM instance name convention"
  default     = "web"
}

variable "number_of_instances" {
  description = "VM number of instances"
  type        = number
  default     = 3
}
