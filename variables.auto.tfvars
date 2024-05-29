# variables.auto.tfvars
prox = {
  node_name = "prox-1"
  endpoint  = "https://192.1.1.1:8006"
  insecure  = true
}

prox_auth = {
  username  = "root"
  api_token = "terraform@pve!provider=<token>"
}

vm_dns = {
  domain  = "."
  servers = ["1.1.1.1", "8.8.8.8"]
}

vm_user      = "user"
vm_password  = "<HASHED PASSWORD>" // docker run -it --rm alpine mkpasswd --method=SHA-512 <PASSWORD>
host_pub-key = "<PUBLIC SSH KEY>"

k8s-version        = "1.29"
cilium-cli-version = "0.16.4"