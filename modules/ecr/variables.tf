variable "mutability" {
  description = "describe mutability of the image"
  type        = string
  default = "IMMUTABLE"
}

variable "image_count_to_keep" {
  description = "describe no.of images to be created"
  type        = number
  default = 1
}

variable "services" {
  description = "List of ECR repository names"
  type        = list(string)
}
