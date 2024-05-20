# Usage
```terraform
module "vpc" {
    <!-- Clone contents then source directly -->
  source = "vpc"

  name = "fedramp-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
```

## Default Module Configuration
The majority of base module configuration comes from [terraform-aws-modules](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master). However, this module is scoped down to limit to IPv4 support and follow FedRAM Moderate guidelines e.g. eliminating map to public IP on EC2 instance launch.