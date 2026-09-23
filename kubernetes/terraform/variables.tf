variable "proxmox_api_token" {
  type    = string
sensitive = true
}

variable "target_node" {
  type    = string
  default = "infra"
}

variable "proxmox_host_ip" {
  type    = string
  default = "100.93.29.93"
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "ssh_private_key" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}
