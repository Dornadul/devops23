provider "aws" {
   region = "us-east-1" #set your desired aws region
}

resourse "aws_instance" "example" {
   ami   ="ami-050441875166"
   instance type="t2-micro"
}

variable "region" {
    default = "es-east-1"
}
data "aws_availability_zones" "available" {}
locals {
    cluster_name = "Aws-EKS-Cluster"
}
module vpc {
    source = "terraform-aws-modules/vpc/aws"

    name = "Aws-EKS-VPC"
    cidr = "10.0.0.0/16"

    azs = data.aws_availability_zones.available.names
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets =  ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true

  enable_dns_hostnames= true
tags = {
    "Name" = "Aws-EKS-VPC"
}
public_subnet_tags = {
    "Name" = "EKS-Public-Subnet"
}
private_subnet_tags = {
    "Name" = "EKS-Private-Subnet"
}
}

resource "aws_security_group" "worker_group_one" {
    name_prefix = "worker_group_one"
    vpc_id = module.vpc.vpc_id
ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
cidr_blocks = [
            "10.0.0.0/8"
        ]
    }
}
resource "aws_security_group" "worker_group_two" {
    name_prefix = "worker_group_two"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
cidr_blocks = [
            "10.0.0.0/8"
        ]
    }
}
resource "aws_security_group" "all_worker_management" {
    name_prefix = "all_worker_management"
    vpc_id = module.vpc.vpc_id
ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
cidr_blocks = [
            "10.0.0.0/8"
        ]
    }
}

module "eks"{
    source = "terraform-aws-modules/eks/aws"
    version = "17.18.0"
    cluster_name = local.cluster_name
    cluster_version = "1.23"
    subnets = module.vpc.private_subnets
tags = {
        Name = "Aws-EKS-Cluster"
    }
vpc_id = module.vpc.vpc_id
    workers_group_defaults = {
        root_volume_type = "gp3"
    }
worker_groups = [
        {
            name = "Worker-Group-1"
            instance_type = "t2.micro"
            asg_desired_capacity = 2
            additional_security_group_ids = [aws_security_group.worker_group_one.id]
        },
        {
            name = "Worker-Group-2"
            instance_type = "t2.micro"
            asg_desired_capacity = 1
            additional_security_group_ids = [aws_security_group.worker_group_two.id]
        },
    ]
}

data "aws_eks_cluster" "cluster" {
    name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
    name = module.eks.cluster_id
}

provider "kubernetes" {

    host = data.aws_eks_cluster.cluster.endpoint
    token = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64encode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

output "cluster_id" {
    value = module.eks.cluster_id
}
output "cluster_endpoint" {
    value = module.eks.cluster_endpoint
}

provider "aws" {
 region = "us-east-1" 
} 
resource "aws_s3_bucket" "my_bucket" { 

bucket = "my-unique-bucket-name" 

tags = { Name = "MyS3Bucket" Environment = "Production" } 

}

