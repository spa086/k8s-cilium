# k8s-config.tf
resource "proxmox_virtual_environment_download_file" "debian_12_generic_image" {
  provider     = proxmox.prox
  node_name    = var.prox.node_name
  content_type = "iso"
  datastore_id = "nas"

  file_name          = "debian-12-generic-amd64-20240201-1644.img"
  url                = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  checksum           = "f7ac3fb9d45cdee99b25ce41c3a0322c0555d4f82d967b57b3167fce878bde09590515052c5193a1c6d69978c9fe1683338b4d93e070b5b3d04e99be00018f25"
  checksum_algorithm = "sha512"
}

# Make sure the "Snippets" content type is enabled on the target datastore in Proxmox before applying the configuration below.
# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/guides/cloud-init.md
resource "proxmox_virtual_environment_file" "cloud-init-ctrl-01" {
  provider     = proxmox.prox
  node_name    = var.prox.node_name
  content_type = "snippets"
  datastore_id = "nve"

  source_raw {
    data = templatefile("./cloud-init/k8s-control-plane.yaml.tftpl", {
      common-config = templatefile("./cloud-init/k8s-common.yaml.tftpl", {
        hostname    = "k8s-ctrl-01"
        username    = var.vm_user
        password    = var.vm_password
        pub-key     = var.host_pub-key
        k8s-version = var.k8s-version
        kubeadm-cmd = "kubeadm init --skip-phases=addon/kube-proxy"
      })
      username           = var.vm_user
      cilium-cli-version = var.cilium-cli-version
      cilium-cli-cmd     = "HOME=/home/${var.vm_user} KUBECONFIG=/etc/kubernetes/admin.conf cilium install --set kubeProxyReplacement=true"
    })
    file_name = "cloud-init-k8s-ctrl-01.yaml"
  }
}

resource "proxmox_virtual_environment_file" "cloud-init-worker" {
  count = 3
  provider     = proxmox.prox
  node_name    = var.prox.node_name
  content_type = "snippets"
  datastore_id = "nve"

  source_raw {
    data = templatefile("./cloud-init/k8s-worker.yaml.tftpl", {
      common-config = templatefile("./cloud-init/k8s-common.yaml.tftpl", {
        hostname    = "k8s-work-${count.index + 1}"
        username    = var.vm_user
        password    = var.vm_password
        pub-key     = var.host_pub-key
        k8s-version = var.k8s-version
        kubeadm-cmd = module.kubeadm-join.stdout
      })
    })
    file_name = "cloud-init-k8s-work-${count.index + 1}.yaml"
  }
}
