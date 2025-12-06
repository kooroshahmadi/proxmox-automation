# Update with your Proxmox IP
proxmox_endpoint = "https://192.168.1.100:8006/api2/json"

# LEAVE TOKEN EMPTY HERE. 
# We will inject the token on the Controller VM so you don't commit secrets to GitHub.
proxmox_token = "" 

vms = {
  "alpine-worker-01" = {
    vmid     = 601
    cores    = 1
    memory   = 512
    packages = ["vim", "curl", "htop"]
  }
}
