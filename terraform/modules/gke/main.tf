# main.tf - GKE module

terraform {
    required_providers {
        google = "~> 3.32.0"
        google-beta = "~> 3.32.0"

        null = "~> 2.1"
        local = "~> 1.4"
        random = "~> 2.3"
    }
}

locals {
    zone = var.cluster["location"]
    region = join("-", slice(split("-", var.cluster["location"]), 0, 2))

    oauth_scopes = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/pubsub",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/servicecontrol",
        "https://www.googleapis.com/auth/trace.append",
        "https://www.googleapis.com/auth/compute",
        "https://www.googleapis.com/auth/cloud-platform"
    ]

    username = "kubernetes-admin"
}

resource "random_id" "password" {
    byte_length = 18
}

data "google_container_engine_versions" "kubernetes_version" {
    #provider = google-beta

    location = local.zone
    version_prefix = "${var.cluster["kubernetes_version"]}."
}

locals {
    master_version = data.google_container_engine_versions.kubernetes_version.latest_master_version
    node_version = data.google_container_engine_versions.kubernetes_version.latest_node_version
}

resource "google_container_cluster" "jarvice" {
    #provider = google-beta

    name = var.cluster["cluster_name"]
    location = local.region
    node_locations = [local.zone]

    min_master_version = local.master_version
    node_version = local.node_version

    #release_channel {
    #    channel = "STABLE"
    #}

    initial_node_count = 2
    remove_default_node_pool = false

    node_config {
        machine_type = "n1-standard-1"
        image_type = "UBUNTU"

        service_account = "default"
        oauth_scopes = local.oauth_scopes

        metadata = {
            disable-legacy-endpoints = "true"
            ssh-keys = <<EOF
${local.username}:${local.ssh_public_key}
EOF
        }

        labels = {
            "node-role.jarvice.io/default" = "true"
        }

        tags = [var.cluster["cluster_name"], "jxedefault"]
    }

    ip_allocation_policy {
        cluster_ipv4_cidr_block = ""
        services_ipv4_cidr_block = ""
    }
    default_max_pods_per_node = 110

    #addons_config {
    #    horizontal_pod_autoscaling {
    #        disabled = false
    #    }
    #    http_load_balancing {
    #        disabled = false
    #    }
    #}

    master_auth {
        username = local.username
        password = random_id.password.hex

        client_certificate_config {
            issue_client_certificate = true
        }
    }

    resource_labels = {
        "cluster_name" = var.cluster["cluster_name"]
    }
}

resource "google_container_node_pool" "jarvice_system" {
    #provider = google-beta

    name = "jxesystem"
    location = local.region
    node_locations = [local.zone]

    cluster = google_container_cluster.jarvice.name
    version = local.node_version

    initial_node_count = local.system_nodes_num
    autoscaling {
        min_node_count = local.system_nodes_num
        max_node_count = local.system_nodes_num * 2
    }

    management {
        auto_repair = true
        auto_upgrade = false
    }

    node_config {
        machine_type = local.system_nodes_type
        image_type = "UBUNTU"

        service_account = "default"
        oauth_scopes = local.oauth_scopes

        metadata = {
            disable-legacy-endpoints = "true"
            ssh-keys = <<EOF
${local.username}:${local.ssh_public_key}
EOF
        }

        labels = {
            "node-role.jarvice.io/jarvice-system" = "true"
        }
        taint = [
            {
                key = "node-role.jarvice.io/jarvice-system"
                value = "true"
                effect = "NO_SCHEDULE"
            }
        ]

        tags = [google_container_cluster.jarvice.name, "jxesystem"]
    }
}

resource "google_container_node_pool" "jarvice_compute" {
    #provider = google-beta

    count = length(var.cluster["compute_node_pools"])

    name = "jxecompute${count.index}"
    location = local.region
    node_locations = [local.zone]

    cluster = google_container_cluster.jarvice.name
    version = local.node_version

    initial_node_count = var.cluster.compute_node_pools[count.index]["nodes_num"]
    autoscaling {
        min_node_count = var.cluster.compute_node_pools[count.index]["nodes_min"]
        max_node_count = var.cluster.compute_node_pools[count.index]["nodes_max"]
    }

    management {
        auto_repair = false
        auto_upgrade = false
    }

    node_config {
        machine_type = var.cluster.compute_node_pools[count.index]["nodes_type"]
        disk_size_gb = var.cluster.compute_node_pools[count.index]["nodes_disk_size_gb"]
        image_type = "UBUNTU"
        #min_cpu_platform = "Intel Skylake"
        #disk_type = "pd-ssd"

        #guest_accelerator {
        #    type = "nvidia-tesla-p100"
        #    count = 1
        #}

        service_account = "default"
        oauth_scopes = local.oauth_scopes

        metadata = {
            disable-legacy-endpoints = "true"
            ssh-keys = <<EOF
${local.username}:${local.ssh_public_key}
EOF
        }

        labels = {
            "node-role.jarvice.io/jarvice-compute" = "true"
        }
        taint = [
            {
                key = "node-role.jarvice.io/jarvice-compute"
                value = "true"
                effect = "NO_SCHEDULE"
            }
        ]

        tags = [google_container_cluster.jarvice.name, "jxecompute${count.index}"]
    }
}
