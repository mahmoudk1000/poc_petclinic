variable "cidr" {
  description = "CIDR block for the Virtual Network."
  type        = string
  default     = "11.0.0.0/16"
}

variable "subnets" {
  description = "Map of subnets with their CIDR blocks."
  type        = map(string)
  default = {
    "private" = "11.0.1.0/24"
    "public"  = "11.0.2.0/24"
  }
}

variable "kube_version" {
  description = "Spesify kubernetes version."
  type        = string
  default     = "1.30"
}

variable "agent_count" {
  description = "Node Count."
  type        = number
  default     = null
}

variable "agents_max_count" {
  description = "Max Node Count."
  type        = number
  default     = 3
}

variable "agents_min_count" {
  description = "Min Node Count."
  type        = number
  default     = 1
}

variable "agent_vm_size" {
  description = "Node type."
  type        = string
  default     = "Standard_DS2_v2"
}

variable "ssh_key_path" {
  description = "SSH key path."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "user" {
  description = "Jumpe Vm username."
  type        = string
  default     = "mau"
}

variable "pass" {
  description = "Jumpe Vm username."
  type        = string
  default     = "mau@1234"
}
