# outputs.tf - EKS module outputs

resource "local_file" "kube_config" {
    filename = pathexpand(local.kube_config["config_path"])
    file_permission = "0600" 
    directory_permission = "0775"
    content = <<EOF
apiVersion: v1
kind: Config
preferences:
  colors: true
current-context: ${module.eks.cluster_id}
contexts:
- context:
    cluster: ${module.eks.cluster_id}
    namespace: default
    user: ${module.eks.cluster_id}
  name: ${module.eks.cluster_id}
clusters:
- cluster:
    server: ${local.kube_config["host"]}
    certificate-authority-data: ${local.kube_config["cluster_ca_certificate"]}
  name: ${module.eks.cluster_id}
users:
- name: ${module.eks.cluster_id}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - token
      - -i
      - ${module.eks.cluster_id}
      command: aws-iam-authenticator
      env: null
EOF
}

output "kube_config" {
    value = local.kube_config
}

locals {
    helm_jarvice_values = yamldecode(module.helm.metadata["jarvice"]["values"])
    ingress_host = lookup(local.helm_jarvice_values["jarvice"], "JARVICE_CLUSTER_TYPE", "upstream") == "downstream" ? local.helm_jarvice_values["jarvice_k8s_scheduler"]["ingressHost"] : local.helm_jarvice_values["jarvice_mc_portal"]["ingressHost"]
}

output "cluster_info" {
    value = <<EOF
===============================================================================

    EKS cluster name: ${var.cluster.meta["cluster_name"]}
EKS cluster location: ${var.cluster.location["region"]}

       JARVICE chart: ${module.helm.jarvice_chart["version"]}
   JARVICE namespace: ${module.helm.metadata["jarvice"]["namespace"]}

Execute the following to begin using kubectl/helm with the new cluster:

export KUBECONFIG=${local.kube_config["config_path"]}

${module.common.cluster_output_message}:

https://${local.ingress_host}/

===============================================================================
EOF

    depends_on = [module.helm]
}

