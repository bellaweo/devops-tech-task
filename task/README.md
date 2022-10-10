# devops-tech-task hello-world application

## A terraform configuration to run a simple hello-world app

#### Overview

The directories in this task folder can be thought of as a monorepo where various pieces of code are dependent on each other. The structure looks like this:

* root of task folder directories, `bootstrap`, `ecs` & `vpc`: these are terraform workspaces where a user executes teraform plans.

* root of task folder modules directory, `ecs` & `vpc` folders: these folders are terraform modules which the corresponding workspaces use when the user executes the terraform plans.

The workspaces are standalone and can run independently of each other. But they are also meant to be run in a sequence. The sequence is:

1. run bootstrap first: if the user hasn't already set up iam permissions to the aws account, this workspace configures that. It also creates the s3 remote backends for the vpc and ecs workspaces. (detailed documentation is in the README file in the bootstrap workspace)

2. run vpc second: this creates the vpc which will be used by the ecs workspace. (detailed documentation is in the README file in the vpc workspace)

3. run ecs third: this creates the resources to run the hello-world application. (detailed documentation is in the README file in the ecs workspace)

If you choose not to run the plan in the bootstrap workspace, then you will need to edit the `main.tf` files in the vpc and ecs workspaces. You will want to remove the local and remote state resources, you will want to adjust the backend to support the backend you are presently using, and you will want to adjust the options in the aws provider stanza to support the iam user/role you are presently using.

If you choose not to run the plan in the vpc workspace, then you will need to edit the `main.tf` file in the ecs workspace and add your own values for the ecs module's inputs.

To determine what code goes into what modules, I based my choice on whether the resource in question could be used by more than one other resource. For example, a vpc can be used by more than one ecs cluster. So as this infrastructure grows, we could potentially see a number of workspaces that retrieve their inputs from the outputs of the vpc workspace. And if there is a change to any outputs in the vpc workspace, then we should have something in place to either automatically trigger terraform runs in the dependent workspaces, or we should get a notification that those subsequent workspaces are out of sync with the vpc workspace.

Why did I design this exercise this way? Mainly because I want to create a foundation for building a loosely connected series of small terraform states. Keeping terraform states small is ideal to reduce time when making adjustments to existing workspaces and it is extremely helpful to reduce friction when tasked to destroy resources. But the catch is that we will need to understand the relationships between the various states and when one changes, whether it should trigger a terraform plan in another state. Building these kinds of notifications and/or triggers is a bit out of scope for the exercise in this repository. But the tools do exist to make this happen. Here, I am referring to workflow services such as temporal.io or even a well designed github action would suffice for a smaller collection of terraform states.

The ideal goal of this design is to automate as much of the maintenance processes as possible. Initially, we can map out the relationships between the states and add tools to print out the dependencies and eventually notify us when certain states go out of sync (i.e. they need a new terraform run to pull in their new inputs). After that, we can build workflows that detect the dependency changes and either notify us to run new plans manually, or the workflows can automatically run those plans and ping us to approve them before applying. And with creating the bootstrap workspace, I want to document a process to establish a machine user that only runs terraform which can be used to authenticate to the various aws accounts from an automated process.

#### Writing the code

To write the workspace and module code, I relied heavily on the documentation for the aws terraform provider plus some inspiration from the code in the official vpc terraform module. I did search a few terms for some help to write the ecs module. And I have built a very similar setup at previous jobs so some of this actually came from my own memory. The only third party code I used is the container image for the hello-world application. I pulled the image from dockerhub and the code to build it lives [here](https://github.com/opsxcq/docker-helloworld-http).

After I added the code to enable autoscaling for the hello-world app, I tested the scaling by running grafana's k6 cli tool. My load test ran for 5 minutes and I simulated 500 virtual users. The application scaled up by one task during that 5 minute test.

#### A note on the code to enable ssl access

By default, ssl access to the hello-world app is disabled. This is because the code creates and configures an aws certificate authority. The certificate authority creates the ssl certificate used by the load balancer to enable https access. The aws certificate authority costs a minimum $400 USD so I placed it behind the enable_ssl input variable. You can enable this code by setting that input variable to true. Just keep in mind your aws bill will go up for the month :). I chose the aws certificate authority because the exercise is very terraform focused so I wanted to provide a terraform solution. if I were to build the same service and I wasn't bound by the requirements of this exercise, I would instead use the certificate authority provided by smallstep and configure terraform to import my smallstep created certificate.

Also note that if you do enable ssl access, there will be an output from the ecs workspace for the root ca certificate. You can use that root ca cert to verify the authenticity of the hello-world application ssl certificate.

#### A note on terraform modules

Because this is a monorepo, it is fairly easy to reference a module from a workspace by noting its path relative to the workspace. So calling the ecs module from within the ecs workspace is as easy as adding the source line `"../modules/ecs"`.  Unfortunately, this does not support module versioning. And although its not represented in this exercise, we should expect, as the infrastructure grows, that different workspaces will use the same module (for example, more than one ecs cluster could use the same ecs module but specify different inputs in each cluster's workspace). In this case, I would recommend changing the source line in each workspace to reference the [url of the module directory from github](https://www.terraform.io/language/modules/sources#github) and specifying a git tag to use to note [which git commit of the module to use](https://www.terraform.io/language/modules/sources#selecting-a-revision). With this change in place, pushing out new module versions can happen in a very controlled manner.
