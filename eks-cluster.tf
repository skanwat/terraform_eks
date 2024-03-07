# resource "aws_iam_role" "main-cluster" {
#     name = "main-eks-cluster-iam-role"

#     assume_role_policy = <<POLICY
# {
#     "Version": "2012-10-17",
#     "Statement": [
#     {
#     "Effect": "Allow",
#     "Principal": {
#     "Service": "eks.amazonaws.com"
#     },
#     "Action": "sts:AssumeRole"
#     }
# ]
# }
# POLICY  
# }


# resource "aws_iam_role_policy_attachment" "main-cluster-AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = "${aws_iam_role.main-cluster.name}"
# }

# resource "aws_iam_role_policy_attachment" "main-cluster-AmazonEKSServicePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
#   role       = "${aws_iam_role.main-cluster.name}"
# }


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = "main"
  cluster_version = "1.27"

  vpc_id                         = aws_vpc.main.id
  subnet_ids                     = [aws_subnet.private_subnets["subnet1"].id, aws_subnet.private_subnets["subnet2"].id ]
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}


# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.7.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.20.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}

# resource "aws_eks_cluster" "main-cluster" {
#     name = "main-eks-cluster"
#     role_arn = "${aws_iam_role.main-cluster.arn}"

#     vpc_config {
#         subnet_ids = [aws_subnet.public_subnets["subnet1"].id, aws_subnet.public_subnets["subnet2"].id]
#     }

#     depends_on = [ 
#         aws_iam_role_policy_attachment.main-cluster-AmazonEKSClusterPolicy,
#         aws_iam_role_policy_attachment.main-cluster-AmazonEKSServicePolicy 
#         ]
   
  
# }