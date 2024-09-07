variable "fleet_count" {
  description = "Node Count"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Node type"
  type        = string
  default     = "Standard_D4_v3"
}

variable "ssh_key_path" {
  description = "SSH key path"
  type        = string
  default     = "~/.ssh/id_ansible.pub"
}

variable "admin_username" {
  description = "Wheel User Name"
  type        = string
  default     = "kube"
}

variable "admin_password" {
  description = "Wheel User Password"
  type        = string
  default     = "Mou@1234"
}

variable "white_list_ips" {
  description = "Whitelist IPs"
  type        = list(string)
  default     = ["197.48.152.52"]
}
