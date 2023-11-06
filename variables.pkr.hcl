variable "image" {
  type    = string
  default = "alpine"
}

variable "repository" {
  type = string
}

variable "registry" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "vault_addr" {
  type = string
}

variable "packages" {
  type = list(string)
  default = [
    "ansible",
    "curl",
    "git",
    "gnupg",
    "iptables",
    "jq",
    "make",
    "openssl",
    "openssh-client",
    "rclone",
    "sshpass",
    "xorriso",
  ]
}