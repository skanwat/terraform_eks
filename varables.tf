variable "public_subnet" {
    type = map
    default = {
        "subnet1" = {
            "cidr_block" = "10.0.0.0/24"
            "az" = "ap-south-1a"
        }
        "subnet2" = {
             "cidr_block" = "10.0.1.0/24"
             "az" = "ap-south-1b"
        }
        
    }
}

variable "private_subnets" {
    type = map
    default = {
        "subnet1" = {
            "cidr_block" = "10.0.2.0/24"
            "az" = "ap-south-1a"
        }
        "subnet2" = {
             "cidr_block" = "10.0.3.0/24"
             "az" = "ap-south-1b"
        }
        
    }
}

variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group. Defaults to AL2_x86_64. Valid values: AL2_x86_64, AL2_x86_64_GPU."
  type = string 
  default = "AL2_x86_64"
}

variable "disk_size" {
  description = "Disk size in GiB for worker nodes. Defaults to 20."
  type = number
  default = 20
}

variable "instance_types" {
  type = list(string)
  default = ["t3.medium"]
  description = "Set of instance types associated with the EKS Node Group."
}