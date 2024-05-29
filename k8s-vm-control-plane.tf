# k8s-vm-control-plane.tf
resource "proxmox_virtual_environment_vm" "k8s-ctrl-01" {
  count = 1
  provider  = proxmox.prox
  node_name = var.prox.node_name

  name        = "k8s-cp-${count.index +1}"
  description = "k8s master, managed by tofu"
  tags        = ["k8s", "control-plane"]
  on_boot     = true
  vm_id       = "500${count.index + 1}"

  

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge      = "vmbr0"
    
  }

  

  disk {
    datastore_id = "nve"
    file_id      = proxmox_virtual_environment_download_file.debian_12_generic_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 32
    file_format  = "raw"
  }

  #boot_order = ["virtio0"]

  agent {
    enabled = true
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  initialization {
    dns {
      domain  = var.vm_dns.domain
      servers = var.vm_dns.servers
    }
    ip_config {
      ipv4 {
        address = "192.168.1.20${count.index + 1}/24"
        gateway = "192.168.1.1"
      }
    }

    datastore_id      = "nve"
    user_data_file_id = proxmox_virtual_environment_file.cloud-init-ctrl-01.id
  }
}

output "ctrl_01_ipv4_address" {
  depends_on = [proxmox_virtual_environment_vm.k8s-ctrl-01]
  value      = proxmox_virtual_environment_vm.k8s-ctrl-01[0].ipv4_addresses[1][0]
}

resource "local_file" "ctrl-01-ip" {
  content         = proxmox_virtual_environment_vm.k8s-ctrl-01[0].ipv4_addresses[1][0]
  filename        = "output/ctrl-01-ip.txt"
  file_permission = "0644"
}

module "kube-config" {
  depends_on   = [local_file.ctrl-01-ip]
  source       = "Invicton-Labs/shell-resource/external"
  version      = "0.4.1"
  command_unix = "ssh -o StrictHostKeyChecking=no ${var.vm_user}@${local_file.ctrl-01-ip.content} cat /home/${var.vm_user}/.kube/config"
}

resource "local_file" "kube-config" {
  content         = module.kube-config.stdout
  filename        = "output/config"
  file_permission = "0600"
}

module "kubeadm-join" {
  depends_on   = [local_file.kube-config]
  source       = "Invicton-Labs/shell-resource/external"
  version      = "0.4.1"
  command_unix = "ssh -o StrictHostKeyChecking=no ${var.vm_user}@${local_file.ctrl-01-ip.content} /usr/bin/kubeadm token create --print-join-command"
}
