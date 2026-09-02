resource "aws_ecr_repository" "this" {
  for_each = toset(var.services)

  name                 = each.value
  image_tag_mutability = var.mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = each.value
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_count_to_keep} images"

        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_count_to_keep
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}