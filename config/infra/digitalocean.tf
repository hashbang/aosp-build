variable "name" {
  type    = string
}

variable "disk" {
  type    = string
}

variable "region" {
  type    = string
  default = "nyc1"
}

resource "digitalocean_volume" "build-storage" {
  region = "${var.region}"
  name = "${var.name}"
  size = "${var.disk}"
  initial_filesystem_type = "ext4"
  description = "Storage for ${var.name} Android build system"
}
