# locals.tf - K8s module local variable definitions

locals {
    jarvice_override_yaml_file = replace("${var.cluster.helm.jarvice["override_yaml_file"]}", "<cluster_name>", "${var.cluster["cluster_name"]}")

    jarvice_helm_override_yaml = fileexists(local.jarvice_override_yaml_file) ? "${file("${local.jarvice_override_yaml_file}")}" : ""

    jarvice_helm_values = merge(lookup(yamldecode("XXXdummy: value\n\n${file("values.yaml")}"), "jarvice", {}), lookup(yamldecode("XXXdummy: value\n\n${local.jarvice_helm_override_yaml}"), "jarvice", {}), lookup(yamldecode("XXXdummy: value\n\n${var.global.helm.jarvice["override_yaml_values"]}"), "jarvice", {}), lookup(yamldecode("XXXdummy: value\n\n${var.cluster.helm.jarvice["override_yaml_values"]}"), "jarvice", {}))

    jarvice_cluster_type = local.jarvice_helm_values["JARVICE_CLUSTER_TYPE"] == "downstream" ? "downstream" : "upstream"
}

locals {
    kube_config = {
        "config_path" = var.cluster["kube_config"],
        "host" = null,
        "cluster_ca_certificate" = null,
        "client_certificate" = null,
        "client_key" = null,
        "token" = null,
        "username" = null,
        "password" = null
    }
}

locals {
    jarvice_config = {
        "ingress_host_path" = "~/.terraform-jarvice/ingress-tf.k8s.${var.cluster["cluster_name"]}"
        "loadbalancer_host_path" = "~/.terraform-jarvice/loadbalancer-tf.k8s.${var.cluster["cluster_name"]}"
    }
}

locals {
    jarvice_ingress_name = local.jarvice_cluster_type == "downstream" ? "jarvice-k8s-scheduler" : "jarvice-mc-portal"

    storage_class_provisioner = ""
    cluster_override_yaml_values = <<EOF
# K8s cluster override values
#jarvice:
#  JARVICE_PVC_VAULT_NAME: ${local.jarvice_helm_values["JARVICE_PVC_VAULT_NAME"] == null ? "persistent" : local.jarvice_helm_values["JARVICE_PVC_VAULT_NAME"]}
#  JARVICE_PVC_VAULT_STORAGECLASS: ${local.jarvice_helm_values["JARVICE_PVC_VAULT_STORAGECLASS"] == null ? "jarvice-user" : local.jarvice_helm_values["JARVICE_PVC_VAULT_STORAGECLASS"]}
#  JARVICE_PVC_VAULT_STORAGECLASS_PROVISIONER: ${local.storage_class_provisioner}
#  JARVICE_PVC_VAULT_ACCESSMODES: ${local.jarvice_helm_values["JARVICE_PVC_VAULT_ACCESSMODES"] == null ? "ReadWriteOnce" : local.jarvice_helm_values["JARVICE_PVC_VAULT_ACCESSMODES"]}
#  JARVICE_PVC_VAULT_SIZE: ${local.jarvice_helm_values["JARVICE_PVC_VAULT_SIZE"] == null ? 10 : local.jarvice_helm_values["JARVICE_PVC_VAULT_SIZE"]}
EOF
}

locals {
    cluster_output_message = local.jarvice_cluster_type == "downstream" ? "Add the downstream cluster URL to an upstream JARVICE cluster" : "Open the portal URL to initialize JARVICE"
}
