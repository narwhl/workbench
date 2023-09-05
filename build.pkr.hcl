packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

data "http" "packer_version" {
  url = "https://api.github.com/repos/hashicorp/packer/releases/latest"
}

data "http" "terraform_version" {
  url = "https://api.github.com/repos/hashicorp/terraform/releases/latest"
}

data "http" "vault_version" {
  url = "https://api.github.com/repos/hashicorp/vault/releases/latest"
}

data "http" "sops_version" {
  url = "https://api.github.com/repos/getsops/sops/releases/latest"
}

data "http" "tailscale_version" {
  url = "https://api.github.com/repos/tailscale/tailscale/releases/latest"
}

locals {
  version           = "${formatdate("YY.MM.", timestamp())}${floor(convert(formatdate("D", timestamp()), number) / 7)}"
  packer_version    = trimprefix(jsondecode(data.http.packer_version.body).name, "v")
  terraform_version = trimprefix(jsondecode(data.http.terraform_version.body).name, "v")
  vault_version     = trimprefix(jsondecode(data.http.vault_version.body).name, "v")
  sops_version      = trimprefix(jsondecode(data.http.sops_version.body).tag_name, "v")
  tailscale_version = trimprefix(jsondecode(data.http.tailscale_version.body).tag_name, "v")
}

source "docker" "alpine" {
  image  = var.image
  commit = true
  changes = [
    "LABEL version=${local.version}",
    "ENV VAULT_ADDR ${var.vault_addr}",
    "ENTRYPOINT [\"/bin/sh\", \"-c\"]"
  ]
}

build {
  name = "workbench"
  sources = [
    "source.docker.alpine"
  ]

  provisioner "shell" {
    inline = [
      "apk add --update --no-cache ansible curl git gnupg iptables jq make openssl openssh-client rclone sshpass xorriso",
      "curl -sSL https://pkgs.tailscale.com/stable/tailscale_${local.tailscale_version}_amd64.tgz -o tailscale_${local.tailscale_version}_amd64.tgz",
      "curl -sSL https://github.com/getsops/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64 -o sops",
      "curl -sSL https://releases.hashicorp.com/packer/${local.packer_version}/packer_${local.packer_version}_linux_amd64.zip -o packer_${local.packer_version}_linux_amd64.zip",
      "curl -sSL https://releases.hashicorp.com/terraform/${local.terraform_version}/terraform_${local.terraform_version}_linux_amd64.zip -o terraform_${local.terraform_version}_linux_amd64.zip",
      "curl -sSL https://releases.hashicorp.com/vault/${local.vault_version}/vault_${local.vault_version}_linux_amd64.zip -o vault_${local.vault_version}_linux_amd64.zip",
      "unzip packer_${local.packer_version}_linux_amd64.zip && unzip terraform_${local.terraform_version}_linux_amd64.zip && unzip vault_${local.vault_version}_linux_amd64.zip && tar xzf tailscale_${local.tailscale_version}_amd64.tgz",
      "chmod +x packer terraform vault sops tailscale_${local.tailscale_version}_amd64/tailscale tailscale_${local.tailscale_version}_amd64/tailscaled && mv packer terraform vault sops tailscale_${local.tailscale_version}_amd64/tailscale tailscale_${local.tailscale_version}_amd64/tailscaled /usr/local/bin/",
      "rm -rf packer_${local.packer_version}_linux_amd64.zip terraform_${local.terraform_version}_linux_amd64.zip vault_${local.vault_version}_linux_amd64.zip tailscale_${local.tailscale_version}_amd64 tailscale_${local.tailscale_version}_amd64.tgz",
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = var.repository
      tags       = ["latest", local.version]
    }

    post-processor "docker-push" {
      login          = true
      login_server   = var.registry
      login_username = var.username
      login_password = var.password
    }
  }
}

