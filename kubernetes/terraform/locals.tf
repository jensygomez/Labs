locals {
  cluster_nodes = { for k, v in var.all_nodes : k => v if v.lab == var.lab }
}
