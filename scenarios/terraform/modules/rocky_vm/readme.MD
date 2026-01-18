# Módulo Terraform: rocky_vm

# rocky_vm Terraform Module

## Purpose

This module clones a pre-existing Rocky Linux base VM and boots it as a lab instance.

It does NOT:
- create networks
- install services
- manage roles
- create multiple VMs

All services (WEB, DB, DNS, PROXY) must already exist in the base image.

## Workflow

1. A healthy base VM is prepared manually
2. A snapshot or qcow2 base image is created
3. Terraform clones the image
4. cloud-init injects lab-specific faults

## Inputs

- lab_name
- base_image
- memory
- vcpus
- cloudinit_iso

## Outputs

- vm_name
- vm_id



jensy@mx:~/Labs/scenarios/terraform/modules/rocky_vm
.
├── main.tf
├── outputs.tf
├── readme.MD
└── variables.tf