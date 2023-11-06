packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

data "http" "upstream" {
  url = "https://artifact.narwhl.dev/upstream.json"
}

locals {
  version  = "${formatdate("YY.MM.", timestamp())}${floor(convert(formatdate("D", timestamp()), number) / 7)}"
  upstream = jsondecode(data.http.upstream.body).syspkgs
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
      "apk add --update --no-cache ${join(" ", var.packages)}}",
      "curl -sSL ${upstream.tailscale.url} -o ${upstream.tailscale.filename}",
      "curl -sSL ${upstream.sops.url} -o sops",
      "curl -sSL ${upstream.packer.url} -o ${upstream.packer.filename}",
      "curl -sSL ${upstream.terraform.url} -o ${upstream.terraform.filename}",
      "curl -sSL ${upstream.vault.url} -o ${upstream.vault.filename}",
      "unzip ${upstream.packer.filename} && unzip ${upstream.terraform.filename} && unzip ${upstream.vault.filename} && tar xzf ${upstream.tailscale.filename}",
      "chmod +x packer terraform vault sops tailscale_${upstream.tailscale.version}_amd64/tailscale tailscale_${upstream.tailscale.version}_amd64/tailscaled && mv packer terraform vault sops tailscale_${upstream.tailscale.version}_amd64/tailscale tailscale_${upstream.tailscale.version}_amd64/tailscaled /usr/local/bin/",
      "rm -rf ${upstream.packer.filename} ${upstream.terraform.filename} ${upstream.vault.filename} tailscale_${upstream.tailscale.version}_amd64 ${upstream.tailscale.filename}",
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

