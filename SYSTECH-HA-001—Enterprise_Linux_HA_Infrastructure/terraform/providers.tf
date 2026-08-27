terraform {
  required_version = ">= 1.6.0"
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = ">= 0.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

provider "incus" {
  remote {
    name = "incus-host"
  }
}
