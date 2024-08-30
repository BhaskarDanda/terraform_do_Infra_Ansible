resource "digitalocean_ssh_key" "example" {
  name       = "my-ssh-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
resource "digitalocean_droplet" "web" {
  name   = "infra-ansible"
  image  = "ubuntu-20-04-x64"
  size   = "s-1vcpu-1gb"
  region = "blr1"
  ssh_keys = [digitalocean_ssh_key.example.id]
  tags = ["web"]

  provisioner "local-exec" {
    command = "echo ${self.ipv4_address} > inventory.ini"
  }
}
resource "null_resource" "ansible" {
  depends_on = [digitalocean_droplet.web]

  provisioner "local-exec" {
    command = <<EOT
      export SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
      ansible-playbook -i inventory.ini playbook.yml --ssh-common-args "$SSH_OPTIONS"
    EOT
  }
}

output "droplet_ip" {
  value = digitalocean_droplet.web.ipv4_address
}