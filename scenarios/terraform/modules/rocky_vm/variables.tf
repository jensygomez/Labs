# scenarios/terraform/modules/rocky_vm/variables.tf

variable "vm_name" {
  description = "Nombre de la VM"
  type        = string
}

variable "base_image" {
  description = "Ruta al qcow2 base sano"
  type        = string
}

variable "cloudinit_user_data" {
  description = "Contenido user-data de cloud-init"
  type        = string
}

variable "cloudinit_meta_data" {
  description = "Contenido meta-data de cloud-init"
  type        = string
}

variable "memory" {
  description = "RAM en MB"
  type        = number
  default     = 6144
}

variable "vcpus" {
  description = "Cantidad de CPUs"
  type        = number
  default     = 2
}

variable "disk_pool" {
  description = "Storage pool libvirt"
  type        = string
  default     = "default"
}

variable "network" {
  description = "Red libvirt"
  type        = string
  default     = "default"
}
