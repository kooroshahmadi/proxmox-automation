terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_endpoint
  pm_api_token_id     = split("=", var.proxmox_token)[0]
  pm_api_token_secret = split("=", var.proxmox_token)[1]
  pm_tls_insecure     = true
}

# 1. Trigger: Detects if config changes
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
  target_node = "proxmox1"            # UPDATE THIS if your node isn't named 'pve'
  vmid        = each.value.vmid
  clone       = "alpine-template" # We will create this template in Step 2

  cores  = each.value.cores
  memory = each.value.memory
  agent  = 1 

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  os_type = "cloud-init"
  
  # Standard Alpine Cloud images usually use the 'alpine' user or allow root via keys.
  # We will configure the SSH connection to use the key generated in Step 3.
  ciuser  = "root"
  sshkeys = file("~/.ssh/id_rsa.pub") 

  # SAFETY: Destroy and Recreate if config changes
  lifecycle {
    replace_triggered_by = [
      null_resource.vm_config_trigger[each.key]
    ]
  }

  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  disk {
    storage = "local-lvm"
    size    = "4G" # Alpine is small
    type    = "scsi"
  }
  
  # Ensure we get an IP before provisioner tries to connect
  ipconfig0 = "ip=dhcp"
}

# 3. Provisioning: Install Alpine Packages
resource "null_resource" "provisioning" {
  for_each = var.vms

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
      # Wait a moment for network to stabilize
      "sleep 5",
      "apk update",
      "apk add ${join(" ", each.value.packages)}"
    ]
  }
}
