resource "aws_s3_bucket" "tf_example_bucket" {
  bucket = "tf-example-s3-bucket"
  tags =     {
    Name = "tf_example"
    Environment = "test"
  }
}


resource "aws_s3_bucket_notification" "tf_example_notification" {
  bucket = aws_s3_bucket.tf_example_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.tf_example_notif_func.arn
    events = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.tf_example_lambda_permission]
}

/*  Give permission to S3 to invoke Lamda */

resource "aws_lambda_permission" "tf_example_lambda_permission" {
  function_name = aws_lambda_function.tf_example_notif_func.arn
  principal     = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.tf_example_bucket.arn
  action        = "lambda:InvokeFunction"
}


/* define lambda function */
data "archive_file" "index" {
  type        = "zip"
  source_file = "index.mjs"
  output_path = "index.zip"
}

resource "aws_lambda_function" "tf_example_notif_func" {
  filename      = "index.zip"
  function_name = "tf_example_notif_func"
  role          = aws_iam_role.tf_example_iam_assume_role.arn
  handler       = "index.handler"
  source_code_hash = data.archive_file.index.output_base64sha256
  runtime       = "nodejs18.x"
  tags =     {
    Name = "tf_example"
    Environment = "test"
  }

}
/* Assume role */

resource "aws_iam_role" "tf_example_iam_assume_role" {
  name = "tf_example_iam_for_lambda_assume_role"
  assume_role_policy = data.aws_iam_policy_document.tf_example_policy_document_assume_role.json
  tags =     {
    Name = "tf_example"
    Environment = "test"
  }
}

data "aws_iam_policy_document" "tf_example_policy_document_assume_role" {
  statement {
    effect = "Allow"
    principals  {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}


resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.tf_example_notif_func.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}


resource aws_iam_policy function_logging_policy {
  name = "function-logging-policy"
  policy = data.aws_iam_policy_document.function_logging_policy_doc.json
}

data "aws_iam_policy_document" "function_logging_policy_doc" {
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}


resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role = aws_iam_role.tf_example_iam_assume_role.id
  policy_arn = aws_iam_policy.function_logging_policy.arn
}