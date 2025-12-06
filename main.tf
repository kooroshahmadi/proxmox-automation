terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_endpoint
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
}

# 1. Trigger: Detects if config changes (RAM, Cores, Packages)
resource "null_resource" "vm_config_trigger" {
  for_each = var.vms
  triggers = {
    config_signature = md5(jsonencode(each.value))
  }
}

# 2. VM Creation
resource "proxmox_vm_qemu" "alpine_vm" {
  for_each = var.vms

  name        = each.key
  target_node = "pve"            # CHANGE THIS if your Proxmox node is not named 'pve'
  vmid        = each.value.vmid
  clone       = "alpine-template" 

  cores  = each.value.cores
  memory = each.value.memory
  agent  = 1 

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-Init Settings
  os_type = "cloud-init"
  ciuser  = "root"
  sshkeys = file("~/.ssh/id_rsa.pub") 
  ipconfig0 = "ip=dhcp"

  # SAFETY: Destroy and Recreate if config trigger changes
  lifecycle {
    replace_triggered_by = [
      null_resource.vm_config_trigger[each.key]
    ]
  }

  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  disk {
    storage = "local-lvm"
    size    = "4G"
    type    = "scsi"
  }
}

# 3. Provisioning: Install Alpine Packages via SSH
resource "null_resource" "provisioning" {
  for_each = var.vms

  # Wait for VM to be created first
  depends_on = [proxmox_vm_qemu.alpine_vm]

  triggers = {
    vm_id = proxmox_vm_qemu.alpine_vm[each.key].id
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
    host        = proxmox_vm_qemu.alpine_vm[each.key].default_ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      # Wait a few seconds for network/DNS to stabilize
      "sleep 5",
      "apk update",
      "apk add ${join(" ", each.value.packages)}"
    ]
  }
}
