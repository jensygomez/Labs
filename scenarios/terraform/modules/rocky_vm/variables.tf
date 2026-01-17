# scenarios/terraform/modules/rocky_vm/variables.tf

variable "vm_name" {
  type = string
}

variable "base_image" {
  type = string
}

variable "cloudinit_user_data" {
  type = string
}

variable "cloudinit_meta_data" {
  type = string
}
