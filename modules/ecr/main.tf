resource "aws_ecr_repository" "foo" {
    name                 = "bar"

    # Image tag needs to be immutable for the following
    # NIST 800-53 Rev 5
    # CA-9(1)
    # CM-2
    # CM-8(1)
    image_tag_mutability = "IMMUTABLE"

    image_scanning_configuration {
      scan_on_push = true
    }
}