# vpc

## Workspace to manage the vpc used by the devops-tech-task

This workspace configures the inputs for the vpc module located [here](/task/modules/vpc).

Within the `main.tf` file: the local backend is used to retrieve the terraform user's role arn which was created during the terraform run in the bootstrap directory.

To run: get the terraform user's aws key and secret key from the bootstrap workspace's output. Export those values and the aws region to the host environment.
```
export AWS_ACCESS_KEY_ID="< terraform user aws key >"
export AWS_SECRET_ACCESS_KEY="< terraform user aws secret key >"
export AWS_REGION="< aws region >"
```
The `main.tf` file here provides sample inputs to use in order to apply the vpc module. You are welcome to change the values provided to suit your environment. The input variables are:

cidr: a terraform string of the subnet of the vpc to be created, in cidr notation.  
example: "10.0.0.0/16"

private_subnets: a terraform list of subnets to create in the public network, in cidr notation. Subnets need to be a subset of the vpc cidr.  
example: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

public_subnets: a terraform list of subnets to create in the private network, in cidr notation. Subnets need to be a subset of the vpc cidr.  
example: ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

After populating the inputs above, you should be able to run the usual `terraform plan` and `terraform apply` to create the vpc. This should result in a new vpc with a public and private network, an internet gateway, and a nat gateway & eip for each private subnet specified.

This workspace will produce outputs which can be used by the ecs workspace in this repository as values for its inputs.
