# IAM roles that GitHub Actions assumes through OIDC.
# The GitHub OIDC provider was created earlier in this account, so it is looked up, not created.

variable "github_owner" {
  type    = string
  default = "Priyanshzx"
}

variable "github_owner_id" {
  description = "Numeric GitHub owner ID. It appears in the OIDC 'sub' claim: repo:<owner>@<owner_id>/<repo>@<repo_id>"
  type        = string
  default     = "259822784"
}

variable "github_repo" {
  type    = string
  default = "terraform-aws-three-tier"
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  sub_prefix = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@*"
}

# ---------- Plan role: any workflow run from this repo, read-only ----------
data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.sub_prefix}:*"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "github-actions-terraform-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Plan still needs to read state and take the state lock in S3
resource "aws_iam_role_policy" "plan_state" {
  name = "terraform-state-access"
  role = aws_iam_role.plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.state.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.state.arn}/*"
      }
    ]
  })
}

# ---------- Apply role: only the main branch ----------
data "aws_iam_policy_document" "apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.sub_prefix}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "apply" {
  name               = "github-actions-terraform-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_trust.json
}

# Broad on purpose while learning. Tighten later to the services this stack uses.
resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "plan_role_arn" {
  value = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  value = aws_iam_role.apply.arn
}
