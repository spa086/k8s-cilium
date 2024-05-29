# main.tf
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.57.0"
    }
  }
}

provider "proxmox" {
  alias    = "prox"
  endpoint = var.prox.endpoint
  insecure = var.prox.insecure

  api_token = var.prox_auth.api_token
  ssh {
    agent    = true
    username = var.prox_auth.username
  }

  tmp_dir = "/var/tmp"
}