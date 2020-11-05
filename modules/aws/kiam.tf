locals {
  kiam = merge(
    local.helm_defaults,
    {
      name                        = "kiam"
      namespace                   = "kiam"
      chart                       = "kiam"
      repository                  = "https://uswitch.github.io/kiam-helm-charts/charts/"
      server_use_host_network     = true
      create_iam_user             = true
      create_iam_resources        = true
      enabled                     = false
      assume_role_policy_override = ""
      chart_version               = "5.10.0"
      version                     = "v3.6"
      iam_policy_override         = ""
      default_network_policy      = true
      iam_user                    = ""
    },
    var.kiam
  )

  values_kiam = <<VALUES
psp:
  create: true
agent:
  image:
    tag: ${local.kiam["version"]}
  host:
    interface: "eni+"
    iptables: true
  updateStrategy: "RollingUpdate"
  tolerations: ${local.kiam["server_use_host_network"] ? "[{'operator': 'Exists'}]" : "[]"}
  whiteListRouteRegexp: "^(/latest/dynamic/instance-identity/document|/latest/meta-data/placement/availability-zone)$"
  prometheus:
    servicemonitor:
      enabled: ${local.prometheus_operator["enabled"]}
  priorityClassName: ${local.priority_class_ds["create"] ? kubernetes_priority_class.kubernetes_addons_ds[0].metadata[0].name : ""}
server:
  service:
    targetPort: 11443
    port: 11443
  updateStrategy: "RollingUpdate"
  useHostNetwork: ${local.kiam["server_use_host_network"]}
  image:
    tag: ${local.kiam["version"]}
  assumeRoleArn: ${local.kiam["enabled"] && local.kiam["create_iam_resources"] ? aws_iam_role.eks-kiam-server-role[0].arn : ""}
  sslCertHostPath: "/etc/pki/ca-trust/extracted/pem"
  extraEnv:
    - name: AWS_DEFAULT_REGION
      value: ${data.aws_region.current.name}
    - name: AWS_ACCESS_KEY_ID
      value: ${local.kiam["enabled"] && local.kiam["create_iam_resources"] ? aws_iam_access_key.eks-kiam-user-key[0].id : ""}
    - name: AWS_SECRET_ACCESS_KEY
      value: ${local.kiam["enabled"] && local.kiam["create_iam_resources"] ? aws_iam_access_key.eks-kiam-user-key[0].secret : ""}
  prometheus:
    servicemonitor:
      enabled: ${local.prometheus_operator["enabled"]}
  priorityClassName: ${local.priority_class["create"] ? kubernetes_priority_class.kubernetes_addons[0].metadata[0].name : ""}
VALUES
}

data "aws_iam_policy_document" "kiam" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks-kiam-server-node" {
  count = local.kiam["enabled"] && local.kiam["create_iam_resources"] ? 1 : 0
  name  = "tf-eks-${var.cluster-name}-kiam-server-node"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/tf-eks-${var.cluster-name}-kiam-server-role"
    }
  ]
}
EOF

}

resource "aws_iam_role" "eks-kiam-server-role" {
  count       = local.kiam["enabled"] && local.kiam["create_iam_resources"] ? 1 : 0
  name        = "tf-eks-${var.cluster-name}-kiam-server-role"
  description = "Role the Kiam Server process assumes"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${local.kiam["create_iam_user"] ? aws_iam_user.eks-kiam-user[0].arn : local.kiam["iam_user"]}"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "eks-kiam-server-policy" {
  count       = local.kiam["enabled"] && local.kiam["create_iam_resources"] ? 1 : 0
  name        = "tf-eks-${var.cluster-name}-kiam-server-policy"
  description = "Policy for the Kiam Server process"
  policy      = local.kiam["assume_role_policy_override"] == "" ? data.aws_iam_policy_document.kiam.json : local.kiam["assume_role_policy_override"]
}

resource "aws_iam_user" "eks-kiam-user" {
  count = local.kiam["enabled"] && local.kiam["create_iam_resources"] && local.kiam["create_iam_user"] ? 1 : 0
  name  = "tf-eks-${var.cluster-name}-kiam-user"
}

resource "aws_iam_access_key" "eks-kiam-user-key" {
  count = local.kiam["enabled"] && local.kiam["create_iam_resources"] && local.kiam["create_iam_user"] ? 1 : 0
  user  = aws_iam_user.eks-kiam-user[0].name
}

resource "aws_iam_user_policy_attachment" "eks-kiam-user" {
  count      = local.kiam["enabled"] && local.kiam["create_iam_resources"] && local.kiam["create_iam_user"] ? 1 : 0
  user       = aws_iam_user.eks-kiam-user[0].name
  policy_arn = aws_iam_policy.eks-kiam-server-node[0].arn
}

resource "aws_iam_role_policy_attachment" "eks-kiam-server-policy" {
  count      = local.kiam["enabled"] && local.kiam["create_iam_resources"] ? 1 : 0
  role       = aws_iam_role.eks-kiam-server-role[0].name
  policy_arn = aws_iam_policy.eks-kiam-server-policy[0].arn
}

resource "kubernetes_namespace" "kiam" {
  count = local.kiam["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = local.kiam["namespace"]
    }

    name = local.kiam["namespace"]
  }
}

resource "helm_release" "kiam" {
  count                 = local.kiam["enabled"] ? 1 : 0
  repository            = local.kiam["repository"]
  name                  = local.kiam["name"]
  chart                 = local.kiam["chart"]
  version               = local.kiam["chart_version"]
  timeout               = local.kiam["timeout"]
  force_update          = local.kiam["force_update"]
  recreate_pods         = local.kiam["recreate_pods"]
  wait                  = local.kiam["wait"]
  atomic                = local.kiam["atomic"]
  cleanup_on_fail       = local.kiam["cleanup_on_fail"]
  dependency_update     = local.kiam["dependency_update"]
  disable_crd_hooks     = local.kiam["disable_crd_hooks"]
  disable_webhooks      = local.kiam["disable_webhooks"]
  render_subchart_notes = local.kiam["render_subchart_notes"]
  replace               = local.kiam["replace"]
  reset_values          = local.kiam["reset_values"]
  reuse_values          = local.kiam["reuse_values"]
  skip_crds             = local.kiam["skip_crds"]
  verify                = local.kiam["verify"]
  values = [
    local.values_kiam,
    local.kiam["extra_values"]
  ]
  namespace = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
  depends_on = [
    helm_release.prometheus_operator
  ]
}

resource "kubernetes_network_policy" "kiam_default_deny" {
  count = local.kiam["enabled"] && local.kiam["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kiam.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kiam_allow_namespace" {
  count = local.kiam["enabled"] && local.kiam["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kiam.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kiam_allow_requests" {
  count = local.kiam["enabled"] && local.kiam["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kiam.*.metadata.0.name[count.index]}-allow-requests"
    namespace = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["kiam"]
      }

      match_expressions {
        key      = "component"
        operator = "In"
        values   = ["server"]
      }
    }

    ingress {
      ports {
        port     = "grpclb"
        protocol = "TCP"
      }

      from {
        namespace_selector {
        }
        pod_selector {
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kiam_allow_monitoring" {
  count = local.kiam["enabled"] && local.kiam["default_network_policy"] && local.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.kiam.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "metrics"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

output kiam-server-role-arn {
  value = aws_iam_role.eks-kiam-server-role.*.arn
}

output kiam-server-role-name {
  value = aws_iam_role.eks-kiam-server-role.*.name
}
