# ecs

## Workspace to manage the ecs service used by the devops-tech-task

This workspace configures the inputs for the ecs module located [here](/task/modules/ecs).

The local backend is used to retrieve the terraform user's role arn which was created during the terraform run in the bootstrap directory.

The remote s3 backend is used to retrieve the outputs from the vpc workspace which are then used as inputs to the ecs module. If you do not run the code in the vpc workspace, then you will want to edit the `main.tf` file here and supply your own variable inputs.

To run: get the terraform user's AWS key and secret key from the bootstrap workspace's output. Export those values and the aws region to the host environment.
```
export AWS_ACCESS_KEY_ID="< terraform user aws key >"
export AWS_SECRET_ACCESS_KEY="< terraform user aws secret key >"
export AWS_REGION="< aws region >"
```
The `main.tf` file here provides sample inputs (i.e. it uses the outputs from the vpc module) to use in order to apply the ecs module. You are welcome to change the values provided to suit your environment. The input variables are:

enable_ssl: a terraform boolean to enable or disable building the resources needed for ssl access to the hello-world application. This is disabled by default.
* example: false

private_subnets: a terraform list of aws subnet ids from the vpc public network, in cidr notation.
* example: ["subnet-b46032ec", "subnet-a46032fc", "subnet-03f720e7de"]

public_subnets: a terraform list of aws subnet ids from the vpc private network, in cidr notation.
* example: ["subnet-b46032ec", "subnet-a46032fc", "subnet-03f720e7de"]

After populating the inputs above, you should be able to run the usual `terraform plan` and `terraform apply` to create the hello-world app. This should result in a new ecs cluster and application load balancer (plus some supporting reources and access over https, if enabled).

This workspace will produce outputs which the user can use to acccess the hello-world application. The main output is the hostname of the load balancer which the user can use as the url for the application. If ssl is enabled, there will also be an output for the certificate authroity root ca certificate which can be used to validate the self-signed certificate produced by the ecs module.
