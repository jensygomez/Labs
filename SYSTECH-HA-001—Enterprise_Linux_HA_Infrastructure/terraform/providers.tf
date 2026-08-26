# terraform/providers.tf
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    incus = {
      source  = "linuxcontainers/incus"
      version = ">= 0.5.0"
    }
  }
}

provider "incus" {
  # Le decimos a OpenTofu que use el remoto que configuramos manualmente
  remote = "incus-host"
  
  # Aceptamos el certificado automáticamente (ya confiamos en él)
  accept_remote_certificate = true
}
