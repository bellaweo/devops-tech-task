# bootstrap

## Minimal code for creating a machine user & s3 remote backend to apply terraform plans to an aws account

Before applying the changes we need to run the devops-tech-task hello world service, we first want to designate an iam user and a remote s3 backend in the account for terraform to use. The code in this directory creates the "terraform" user and the "terraform" role which the user assumes during a terraform run. To keep things simple, this terraform role has administraor access to the aws account. The code in this directory also creates a s3 bucket and a dynamo db table for the s3 backend.

If we are starting out with a brand new aws account, then we want to use the root account user to apply this code. Also, we generally want to perform the terraform commands on our host machine, via the cli. And we *do* want to commit the state file produced to this git repository. Once the terraform user and role are creaed, it is unlikely we will need to change this configuration (except to rotate the terraform user's access keys).

To run: assign the root user an aws key and secret key. Export those values and the aws region to the host environment.
```
export AWS_ACCESS_KEY_ID="< root user aws key >"
export AWS_SECRET_ACCESS_KEY="< root user aws secret key >"
export AWS_REGION="< aws region >"
```
Copy the `input.tfvars.example` file to `input.tfvars` and add the value for the gpg_key variable (instructions are in the `input.tfvars.example` file).

Terraform plan.
```
terraform plan -var-file="input.tfvars"
```
Terraform apply.
```
terraform apply -var-file="input.tfvars"
```
Make sure to commit the new terraform.tfstate file to this git repository.

If you no longer need the root aws keys, delete them.

Both the vpc and ecs terraform workspaces will use this new terraform user to apply changes. You will need to retrieve this user's aws keys which are available here as outputs. To unencrypt the secret key, run `terraform output -raw terraform_aws_key_secret | base64 --decode | gpg --decrypt` (you may need to adjust the command if you are not using a gpg key from your host machine's gpg configuration).

When considering security best practices, usually the terraform user configuration spans multiple aws accounts. Usually there is an admin designated account that contains the user while the account that will hold the resources contains the role. For the purposes of this exercise, both the user and role exist in the same aws account.
