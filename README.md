# Workbench OCI Image

This repository builds a custom OCI image and push to Github's container registry on a weekly basis, the image contains software packages as follows:
- ansible
- curl
- git
- iptables
- jq
- make
- openssl
- openssh-client
- packer
- rclone
- sops
- sshpass
- tailscale
- terraform
- vault
- xorriso

its purpose is to consolidate commonly used packages into a single OCI image for CI platform to pull and faciliate CI workflows

HashiCorp Packer is used as the image builder, it utilises its Docker plugin for building container images.

### Requirements

Some variables are required and listed below for identifying image and authenticating to the container registry:

`repository` - the path the container image is going to be pull from

`registry` - the hostname for the container registry

`username` - the username for logging and identifying to the container registry

`password` - for authentication

### Usage

To initialize and download plugin dependencies, run `packer init .` 

and to build this project, run `packer build .`