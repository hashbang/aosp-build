terraform {
    required_version = ">= 0.12, < 0.13"
    backend "s3" {
        skip_requesting_account_id = true
        skip_credentials_validation = true
        skip_get_ec2_platforms = true
        skip_metadata_api_check = true
    }
}

resource "digitalocean_kubernetes_cluster" "aosp-build" {
    name = "aosp-build"
    region = "nyc1"
    version = "1.12.8-do.f.1"
    node_pool {
        name = "worker-pool"
        size = "s-2vcpu-2gb"
        node_count = 1
    }
}

variable "HOME" {}
variable "GITHUB_CLIENT_ID" {}
variable "GITHUB_CLIENT_SECRET" {}
variable "DRONE_GITHUB_SERVER" {}
variable "DRONE_RPC_SECRET" {}
variable "DRONE_TLS_AUTOCERT" {}
variable "DRONE_SERVER_HOST" {}
variable "DRONE_SERVER_PROTO" {}

locals {
	home = "${var.HOME}"
	github_client_id = "${var.GITHUB_CLIENT_ID}"
	github_client_secret = "${var.GITHUB_CLIENT_SECRET}"
	drone_github_server = "${var.DRONE_GITHUB_SERVER}"
	drone_rpc_secret = "${var.DRONE_RPC_SECRET}"
	drone_tls_autocert = "${var.DRONE_TLS_AUTOCERT}"
	drone_server_host = "${var.DRONE_SERVER_HOST}"
	drone_server_proto = "${var.DRONE_SERVER_PROTO}"
    k8s_config = "${digitalocean_kubernetes_cluster.aosp-build.kube_config[0]}"
    k8s_host = "${local.k8s_config["host"]}"
    k8s_client_key = "${base64decode(local.k8s_config["client_key"])}"
    k8s_client_cert = "${base64decode(local.k8s_config["client_certificate"])}"
    k8s_ca_cert = "${base64decode(local.k8s_config["cluster_ca_certificate"])}"
}

provider "kubernetes" {
    host = "${local.k8s_host}"
    client_certificate = "${local.k8s_client_cert}"
    client_key = "${local.k8s_client_key}"
    cluster_ca_certificate = "${local.k8s_ca_cert}"
}

resource "local_file" "kubernetes_config" {
    content = "${digitalocean_kubernetes_cluster.aosp-build.kube_config.0.raw_config}"
    filename = "${local.home}/.kube/config"
}

resource "kubernetes_pod" "drone" {
  metadata {
    name = "drone"
    labels = {
      app = "drone"
    }
  }
  spec {
    container {
      image = "drone/drone:1.2.0"
      name  = "drone"
	  port {
		container_port = 80
		host_port = 80
      }
      env {
    	name = "DRONE_KUBERNETES_ENABLED"
    	value = false
      }
      env {
    	name = "DRONE_KUBERNETES_NAMESPACE"
    	value = "default"
      }
      env {
    	name = "DRONE_TLS_AUTOCERT"
    	value = "${local.drone_tls_autocert}"
      }
      env {
    	name = "DRONE_GITHUB_SERVER"
    	value = "${local.drone_github_server}"
      }
      env {
    	name = "DRONE_GITHUB_CLIENT_ID"
    	value = "${local.github_client_id}"
      }
      env {
    	name = "DRONE_GITHUB_CLIENT_SECRET"
    	value = "${local.github_client_secret}"
      }
      env {
    	name = "DRONE_RPC_SECRET"
    	value = "${local.drone_rpc_secret}"
      }
      env {
    	name = "DRONE_SERVER_HOST"
    	value = "${local.drone_server_host}"
      }
      env {
    	name = "DRONE_SERVER_PROTO"
    	value = "${local.drone_server_proto}"
      }
    }
  }
}

resource "kubernetes_service" "drone" {
  metadata {
    name = "drone"
  }
  spec {
    selector = {
      app = "${kubernetes_pod.drone.metadata.0.labels.app}"
    }
    port {
	  name = "https"
      port = 443
      target_port = 80
    }
    port {
	  name = "http"
      port = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = "${kubernetes_service.drone.load_balancer_ingress.0.ip}"
}
