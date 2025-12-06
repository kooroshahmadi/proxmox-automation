# Proxmox API URL (Change IP to match your server)
proxmox_endpoint = "https://192.168.1.100:8006/api2/json"

# Credentials (using Password to bypass permission bugs)
proxmox_user     = "root@pam"
proxmox_password = "koorosh7979"

# The VM Configuration
vms = {
  "alpine-worker-01" = {
    vmid     = 601
    cores    = 1
    memory   = 512
    packages = ["vim", "curl", "htop"]
  }
}
