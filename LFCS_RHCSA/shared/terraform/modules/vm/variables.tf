variable "target_node" { type = string }
variable "ssh_public_key" { type = string }

variable "vms" {
  type = map(object({
    vmid        = number
    ip          = string
    cores       = number
    memory      = number
    disk_size   = optional(number, 20)
    extra_disks = optional(list(number), [])
    role        = string
  }))
}
