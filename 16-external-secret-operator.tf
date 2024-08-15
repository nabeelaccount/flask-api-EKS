# Retrieve Accounts Information - ID
data "aws_caller_identity" "account_info" {}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks.name
}

data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

###########################################################################################
# External Secret
###########################################################################################

# Associate OIDC with EKS Service Account
data "aws_iam_policy_document" "secrets_manager_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub" 
      values   = ["system:serviceaccount:external-secrets:eso-service-account"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "secrets_manager_role" {
  name               = "ESOsecretsManagerRole"
  assume_role_policy = data.aws_iam_policy_document.secrets_manager_assume_role_policy.json
}


resource "aws_iam_policy" "secrets_manager_policy" {
  name = "secrets_manager_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds"
      ],
      "Resource" : [
        "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.account_info.account_id}:secret:*",
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  role       = aws_iam_role.secrets_manager_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}


resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

# Deployes the ES Operator and the Secret Store
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.20"

  create_namespace = false

  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "webhook.port"
    value = "9443"
  }
}


##########################################################################################
#  Create a Cluster Secret Store
###########################################################################################
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
}

# Create the kubernetes service account to authenticate the Secret Store below
resource "kubernetes_service_account" "cluster_secret_store" {
  metadata {
    name      = "eso-service-account"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.secrets_manager_role.arn
    }
  }
}


# SECRET STORE: Configures how to connect and autenticate with the AWS services e.g. Secret Manager
resource "kubectl_manifest" "secrets_manager_secret_store" {
    yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: cluster-secret-store
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${var.region}
      auth:
        jwt:
          serviceAccountRef:
            # Service account name
            name: ${kubernetes_service_account.cluster_secret_store.metadata[0].name}
            # Serivice account namespace
            namespace: ${kubernetes_namespace.external_secrets.metadata[0].name}
YAML
}




# resource "kubernetes_manifest" "secrets_manager_secret_store" {
#   depends_on = [helm_release.external_secrets]

#   manifest = {
#     apiVersion = "external-secrets.io/v1beta1"
#     kind       = "ClusterSecretStore"
#     metadata = {
#       name = "cluster-secret-store"
#     }
#     spec = {
#       provider = {
#         aws = {
#           service = "SecretsManager"
#           region  = var.region
#           auth = {
#             jwt = {
#               serviceAccountRef = {
#                 # Service account name
#                 name      = kubernetes_service_account.cluster_secret_store.metadata[0].name,
#                 # Serivice account namespace
#                 namespace = kubernetes_namespace.external_secrets.metadata[0].name
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }
