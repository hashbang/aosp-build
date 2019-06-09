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

locals {
    k8s_config = "${digitalocean_kubernetes_cluster.aosp-build.kube_config[0]}"
    k8s_host = "${local.k8s_config["host"]}"
    k8s_client_key = "${base64decode(local.k8s_config["client_key"])}"
    k8s_client_cert = "${base64decode(local.k8s_config["client_certificate"])}"
    k8s_ca_cert = "${base64decode(local.k8s_config["cluster_ca_certificate"])}"
}

variable "home" {}

provider "kubernetes" {
    host = "${local.k8s_host}"
    client_certificate = "${local.k8s_client_cert}"
    client_key = "${local.k8s_client_key}"
    cluster_ca_certificate = "${local.k8s_ca_cert}"
}

resource "local_file" "kubernetes_config" {
    content = "${digitalocean_kubernetes_cluster.aosp-build.kube_config.0.raw_config}"
    filename = "${var.home}/.kube/config"
}

resource "kubernetes_service_account" "tiller" {
  metadata {
    name = "tiller"
    namespace = "kube-system"
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "tiller" {
    metadata {
        name = "tiller"
    }
    role_ref {
        kind = "ClusterRole"
        name = "cluster-admin"
        api_group = "rbac.authorization.k8s.io"
    }
    subject {
        kind = "ServiceAccount"
        name = "tiller"
        api_group = ""
        namespace = "kube-system"
    }
}

provider "helm" {
    enable_tls = true
    tiller_image = "gcr.io/kubernetes-helm/tiller:v2.14.1"
    service_account = "${kubernetes_service_account.tiller.metadata.0.name}"
    namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"
    kubernetes {
        host = "${local.k8s_host}"
        client_certificate = "${local.k8s_client_cert}"
        client_key = "${local.k8s_client_key}"
        cluster_ca_certificate = "${local.k8s_ca_cert}"
    }
}

data "helm_repository" "stable" {
    name = "stable"
    url  = "https://kubernetes-charts.storage.googleapis.com"
}

#resource "helm_release" "drone" {
#    name = "drone"
#    chart = "stable/drone"
#    set {
#        name  = "some_key"
#        value = "foo"
#    }
#    depends_on = [
#        "data.helm_repository.stable",
#        "kubernetes_service_account.tiller",
#        "kubernetes_cluster_role_binding.tiller",
#    ]
#}
#
