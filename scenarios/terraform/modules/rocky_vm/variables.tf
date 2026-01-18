# scenarios/terraform/modules/rocky_vm/variables.tf

variable "lab_name" {
  description = "Nombre del laboratorio (ej: J01-V01)"
  type        = string
}

variable "base_image" {
  description = "Ruta al qcow2 base sano"
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

variable "cloudinit_iso" {
  description = "Ruta al ISO de cloud-init generado por el engine"
  type        = string
}

variable "disk_pool" {
  description = "Storage pool donde se creará el disco clonado"
  type        = string
  default     = "default"
}

variable "network" {
  description = "Red libvirt a usar (ej: default)"
  type        = string
  default     = "default"
}
