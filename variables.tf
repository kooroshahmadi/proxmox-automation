variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_user" {
  type = string
}

variable "proxmox_password" {
  type = string
  sensitive = true
}

variable "vms" {
  type = map(object({
    vmid     = number
    cores    = number
    memory   = number
    packages = list(string)
  }))
}
