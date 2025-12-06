variable "proxmox_endpoint" { type = string }
variable "proxmox_token"    { type = string }

variable "vms" {
  type = map(object({
    vmid     = number
    cores    = number
    memory   = number
    packages = list(string)
  }))
}
