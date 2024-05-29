# k8s-vm-worker.tf
resource "proxmox_virtual_environment_vm" "k8s-work-01" {
  count = 3
  provider  = proxmox.prox
  node_name = var.prox.node_name

  name        = "k8s-work-${count.index +1}"
  description = "k8s worker, managed by tofu"
  tags        = ["k8s", "worker"]
  on_boot     = true
  vm_id       = "600${count.index + 1}"

 

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  network_device {
    bridge      = "vmbr0"
    
  }

  

  disk {
    datastore_id = "nve"
    file_id      = proxmox_virtual_environment_download_file.debian_12_generic_image.id
    interface    = "virtio0"
    discard      = "on"
    ssd          = true
    size         = 32
  }


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
        address = "192.168.1.21${count.index + 1}/24"
        gateway = "192.168.1.1"
      }
    }

    datastore_id      = "nve"
    user_data_file_id = proxmox_virtual_environment_file.cloud-init-worker[count.index].id
  }


}

output "work_01_ipv4_address" {
  depends_on = [proxmox_virtual_environment_vm.k8s-work-01]
  value      = proxmox_virtual_environment_vm.k8s-work-01[0].ipv4_addresses[1][0]
}

resource "local_file" "work-01-ip" {
  content         = proxmox_virtual_environment_vm.k8s-work-01[0].ipv4_addresses[1][0]
  filename        = "output/work-01-ip.txt"
  file_permission = "0644"
}
