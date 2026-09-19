variable "nodes" {
  type = map(object({ name = string, ip = string, role = string }))
}
variable "role_group_map" { type = map(string) }
variable "output_path" { type = string }
