variable "target_node" { type = string }
variable "ssh_public_key" { type = string }
variable "ssh_private_key" { type = string }
variable "proxmox_host_ip" { type = string }

variable "containers" {
  type = map(object({
    vmid       = number
    ip         = string
    cores      = number
    memory     = number
    disk_size  = number
    role       = string
    privileged = optional(bool, false)
  }))
}
