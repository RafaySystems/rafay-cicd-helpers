#provider "aws" {
#  region = "us-east-1"
#}

resource "random_uuid" "test" {
}

data "aws_iam_policy_document" "doc" {
  statement {
    sid     = "AllowAssumeRoleForAnotherAccount"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [random_uuid.test.result] 
    }
  }
}

resource "aws_iam_role" "eks_access_role" {
  name               = var.aws_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.doc.json 
}

resource "aws_iam_policy" "policy" {
  name        = var.aws_iam_policy_name
  description = "Rafay EKS IAM Policy"
  policy      = "${file("${path.module}/eks-policy.json")}"
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.eks_access_role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}
