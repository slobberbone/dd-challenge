resource "aws_iam_instance_profile" "webapp_profile" {
  name = "webapp-profile"
  role = aws_iam_role.webapp_role.name
}

resource "aws_iam_role" "webapp_role" {
  name               = "webapp-role"
  assume_role_policy = data.aws_iam_policy_document.webapp_assumerole_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ssm-webapp" {
  # name = "ssm_webapp_policy"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.webapp_role.name
  # roles = [aws_iam_role.webapp_role.arn]
}

data "aws_iam_policy_document" "webapp_assumerole_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "webapp_policy_document" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}


resource "aws_iam_role_policy" "webapp_policy" {
  name   = "webapp_policy"
  role   = aws_iam_role.webapp_role.name
  policy = data.aws_iam_policy_document.webapp_policy_document.json
}
