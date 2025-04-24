# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "vm_name_terraformvms" {
  value = azurerm_linux_virtual_machine.terraformvms[*].name
}
