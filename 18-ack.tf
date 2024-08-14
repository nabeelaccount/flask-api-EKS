# https://aws.amazon.com/blogs/database/deploy-amazon-rds-databases-for-applications-in-kubernetes/

data "aws_iam_policy_document" "ack" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ack-rds"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ack" {
  name               = "${aws_eks_cluster.eks.name}-ack"
  assume_role_policy = data.aws_iam_policy_document.ack.json
}

resource "aws_iam_role_policy_attachment" "ack" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  role       = aws_iam_role.ack.name
}


resource "aws_iam_policy" "ack" {
  name = "ack_policy"
  policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
          {
              "Condition": {
                  "StringEquals": {
                      "aws:RequestedRegion": var.region
                  }
              },
              "Action": "rds:*",
              "Resource": "arn:aws:rds:${var.region}:${data.aws_caller_identity.account_info.account_id}:*",
              "Effect": "Allow",
              "Sid": "CreateRds"
          },
          {
              "Action": "rds:DeleteDBInstance",
              "Resource": "*",
              "Effect": "Deny",
              "Sid": "DenyDeleteRds"
          }
      ]
  })
}


resource "kubernetes_service_account" "ack_rds" {
  metadata {
    name      = "ack-rds"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ack.arn
    }
  }
}

resource "helm_release" "ack_rds" {
  name             = "ack-rds"
  namespace        = "kube-system"
  repository       = "oci://public.ecr.aws/aws-controllers-k8s"
  chart            = "rds-chart"
  version          = "1.4.3"
  create_namespace = false
  
  set {
    name  = "aws.region"
    value = var.region
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.ack_rds.metadata[0].name
  }
}


# resource "kubectl_manifest" "secrets_manager_secret_store" {
#     yaml_body = <<YAML
# apiVersion: rds.services.k8s.aws/v1alpha1
# kind: DBSubnetGroup
# metadata:
#   name: rds-postgresql-subnet-group
# spec:
#   name: rds-postgresql-subnet-group
#   description: RDS for app in EKS
#   subnetIDs:
#   - ${aws_subnet.rds_zone1.id}
#   - ${aws_subnet.rds_zone2.id}
#   - ${aws_subnet.rds_zone3.id}
#   tags:
#     - key: stage
#       value: development
#     - key: owner
#       value: dev
# YAML
# }

