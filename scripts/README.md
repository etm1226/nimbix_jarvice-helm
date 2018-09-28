# JARVICE Helm chart deployment scripts

This directory contains helper scripts for JARVICE Helm chart deployments.

See README.md in the top level of this repository for more in depth details
on JARVICE Helm chart installations:
https://github.com/nimbix/jarvice-helm

------------------------------------------------------------------------------

## Code repository of the JARVICE helm chart

It is first necessary to clone this git repository to a client machine:

```bash
$ git clone https://github.com/nimbix/jarvice-helm.git
```

## `jarvice-deploy2eks`

The `jarvice-deploy2eks` script can be used to quickly deploy JARVICE into
an Amazon EKS cluster with a single command line.

It will first verify and, if needed, install software components needed for
interacting with AWS and EKS.  Subsequently, it will create and initialize
an EKS cluster.  That process will take approximately 15 minutes.  That may
vary depending on the settings chosen for the number of EKS nodes and the
accompanying volume sizes.

Next, it will install kubernetes plugins and initialize/configure Tiller
to enable installation of the JARVICE helm chart into the cluster.  Lastly,
it will `helm install` the JARVICE chart and print out URLs for accessing
the JARVICE installation.  It will take around five minutes for the JARVICE
installation and deployment rollout.  The entire process combined,
from start to finish, will be approximately 20 minutes.

Execute `jarvice-deploy2eks` with `--help` to see all of the current command
line options:
```bash
Usage:
  ./scripts/jarvice-deploy2eks [deploy_options] [eks_cluster_options]
  ./scripts/jarvice-deploy2eks --eks-stack-add [eks_cluster_options]
  ./scripts/jarvice-deploy2eks --eks-stack-update <number> [eks_cluster_options]
  ./scripts/jarvice-deploy2eks --eks-stack-delete <number> \
        [--eks-cluster-name <name>] [--aws-region <aws_region>]
  ./scripts/jarvice-deploy2eks --eks-stack-get <number> \
        [--eks-cluster-name <name>] [--aws-region <aws_region>]
  ./scripts/jarvice-deploy2eks --eks-cluster-delete <name> \
        [--aws-region <aws_region>] \
        [--database-vol-delete] [--vault-vols-delete]

Available [deploy_options]:
  --registry-username <username>    Docker registry username for JARVICE system
                                    images
  --registry-password <password>    Docker registry password for JARVICE system
                                    images
  --jarvice-license <license_key>   JARVICE license key
  --jarvice-username <username>     JARVICE platform username for app
                                    synchronization
  --jarvice-apikey <apikey>         JARVICE platform apikey for app
                                    synchronization
  --jarvice-chart-dir <path>        Alternative JARVICE helm chart directory
                                    (optional)

Available [eks_cluster_options]:
  --aws-region <aws_region>         AWS region for EKS cluster
                                    (default: us-west-2)
  --aws-zones <aws_zone_list>       Comma separated zone list for --aws-region
                                    (initial deploy only, optional)
  --eks-cluster-name <name>         EKS cluster name
                                    (default: jarvice)
  --eks-node-type <node_type>       EC2 instance types for EKS nodes
                                    (default: c5.9xlarge)
  --eks-nodes <number>              Number of EKS cluster nodes
                                    (default: 4)
  --eks-nodes-max <number>          Autoscale up to maximum number of nodes
                                    (must be greater than --eks-nodes)
  --eks-nodes-vol-size <number>     Size of the nodes' EBS volume in GB
                                    (default: 100)

See the following link for available EC2 instance types (--eks-node-type):
https://aws.amazon.com/ec2/instance-types/

Example (minimal) deploy command:
$ ./scripts/jarvice-deploy2eks \
    --registry-username <username> \
    --registry-password <password> \
    --jarvice-license <license_key> \
    --jarvice-username <username> \
    --jarvice-apikey <apikey>

Example (minimal) delete command (must explicitly supply cluster name):
$ ./scripts/jarvice-deploy2eks --eks-cluster-delete <name>
```

### AWS Credentials

If you don't already have an AWS user and/or access key, create a user with
the appropriate permissions and/or an access key in the AWS console:
https://console.aws.amazon.com/iam/home?#/users

Before using this script, it will be necessary to set your AWS credentials
with environment variables or put them in the AWS credentials config file:

```bash
$ export AWS_ACCESS_KEY_ID=<aws_access_key>
$ export AWS_SECRET_ACCESS_KEY=<aws_secret_key>
```

```bash
$ mkdir -p ~/.aws
$ cat >~/.aws/credentials <<EOF
[default]
aws_access_key_id = <aws_access_key>
aws_secret_access_key = <aws_secret_key>
EOF
```

See the following link for more details:
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html

### KUBECONFIG

`jarvice-deploy2eks` will use `~/.kube/config` as the default kubeconfig file.
Set the `KUBECONFIG` environment variable to change the default:
```bash
$ export KUBECONFIG=~/.kube/config.eks
```

If the kubeconfig file exists, a new context for the EKS cluster will be added
to it.  If the kubeconfig file doesn't exist, it will be created.

### Execution examples

As seen in the `--help` output, this is the minimal command line one can use
to deploy JARVICE to an EKS cluster:
```bash
$ ./scripts/jarvice-deploy2eks \
    --registry-username <username> \
    --registry-password <password> \
    --jarvice-license <license_key> \
    --jarvice-username <username> \
    --jarvice-apikey <apikey>
```

To deploy a cluster with 10 static EKS nodes:
```bash
$ ./scripts/jarvice-deploy2eks \
    --registry-username <username> \
    --registry-password <password> \
    --jarvice-license <license_key> \
    --jarvice-username <username> \
    --jarvice-apikey <apikey> \
    --eks-nodes 10
```

To deploy a cluster with 10 static EKS nodes with 200GB EBS volumes:
```bash
$ ./scripts/jarvice-deploy2eks \
    --registry-username <username> \
    --registry-password <password> \
    --jarvice-license <license_key> \
    --jarvice-username <username> \
    --jarvice-apikey <apikey> \
    --eks-nodes 10 \
    --eks-nodes-vol-size 200
```

To deploy a cluster with an autoscaling group of 10-20 nodes, use
`--eks-nodes-max`:
```bash
$ ./scripts/jarvice-deploy2eks \
    --registry-username <username> \
    --registry-password <password> \
    --jarvice-license <license_key> \
    --jarvice-username <username> \
    --jarvice-apikey <apikey> \
    --eks-nodes 10 \
    --eks-nodes-max 20
```

To deploy a cluster named `nvidia_gpu_cluster` with an autoscaling group of
10-20 `p3.2xlarge` (NVIDIA GPU enabled) nodes:
```bash
$ ./scripts/jarvice-deploy2eks \
    --registry-username <username> \
    --registry-password <password> \
    --jarvice-license <license_key> \
    --jarvice-username <username> \
    --jarvice-apikey <apikey> \
    --eks-nodes 10 \
    --eks-nodes-max 20 \
    --eks-node-type p3.2xlarge \
    --eks-cluster-name nvidia_gpu_cluster
```
Note: The NVIDIA device plugin will automatically be installed when `p2` or
`p3` node types are used.

To do all of the above in the `us-east-1` region with a specific list of zones:
```bash
$ ./scripts/jarvice-deploy2eks \
    --registry-username <username> \
    --registry-password <password> \
    --jarvice-license <license_key> \
    --jarvice-username <username> \
    --jarvice-apikey <apikey> \
    --eks-nodes 10 \
    --eks-nodes-max 20 \
    --eks-node-type p3.2xlarge \
    --eks-cluster-name nvidia_gpu_cluster \
    --aws-region us-east-1 \
    --aws-zones us-east-1a,us-east-1b,us-east-1e
```

To update the number of nodes in the base stack (0):
```bash
$ ./scripts/jarvice-deploy2eks \
    --eks-stack-update 0 \
    --eks-nodes 20 \
    --eks-nodes-max 30
```

To add a node group stack of 20 `c5.18xlarge` nodes:
```bash
$ ./scripts/jarvice-deploy2eks \
    --eks-stack-add \
    --eks-nodes 20 \
    --eks-node-type c5.18xlarge
```

To list the stacks' details of a cluster in the `us-east-1` region:
```bash
$ ./scripts/jarvice-deploy2eks \
    --eks-stacks-get \
    --aws-region us-east-1
```

To delete a node group stack:
```bash
$ ./scripts/jarvice-deploy2eks \
    --eks-stack-delete 1
```
Note:  The base stack (0) can only be updated, not deleted.

### Cluster removal

In order to remove the EKS cluster, use the `--eks-cluster-delete` flag:
```bash
$ ./scripts/jarvice-deploy2eks \
    --eks-cluster-delete jarvice --aws-region us-west-2
```

To delete the JARVICE database and/or user vault EBS volumes along with the
cluster, the `--database-vol-delete` and/or `--vault-vols-delete` flags must
be explicitly provided:
```bash
$ ./scripts/jarvice-deploy2eks \
    --eks-cluster-delete jarvice --aws-region us-west-2 \
    --database-vol-delete --vault-vols-delete
```
Note:  Preserved JARVICE database and user vault EBS volumes will be reused
if an EKS cluster of the same name is recreated in the same AWS region.

If you had a previous kubeconfig file, the installation will have changed the
`current-context`.  Use `kubectl config get-contexts` to see the available
contexts in the kubeconfig.  Then, if desired, revert the `current-context`
with the following command:
```bash
$ kubectl config set current-context <context_name>
```

### Troubleshooting

If an error occurs while `jarvice-deploy2eks` is creating the cluster, it is
most likely due to an error during creation of the CloudFormation stacks.
The stacks can be viewed via the CloudFormation Stacks link provided below.

If the stack creation complains of a lack of resources, it may recommend a
list of zones which can be used to access the necessary resources.  If so, try
re-running `jarvice-deploy2eks` with the `--aws-zones` flag to request those
zones.

If the error was due to a previously existing Virtual Private Cloud (VPC)
stack of the same name, it will be necessary to delete it manually (see the
VPC management console link below).

If the EC2 load balancers and matching elastic load balancer (ELB) security
groups associated with the Virtual Private Cloud (VPC) of a previous cluster
deployment were not properly cleaned up on cluster deletion, the VPCs
will not be subsequently deleted.  This may cause the allotted VPC limit for
the AWS account to be reached.  In that case, AWS will not allow further VPC
creation during the bring up of new EKS clusters.  Use the the EC2 and VPC
management console links below to manually delete the load balancers and
security groups before deleting the associated VPCs.

### AWS resource links

The `jarvice-deploy2eks` creates a number of AWS resources.  They can be
viewed via the following links.

IAM roles:
https://console.aws.amazon.com/iam/home?#/roles

CloudFormation Stacks (select alternative region if necessary):
https://us-west-2.console.aws.amazon.com/cloudformation/home?#/stacks?filter=active

EKS clusters (select alternative region if necessary):
https://us-west-2.console.aws.amazon.com/eks/home?#/clusters

VPC management console (select alternative region if necessary):
https://us-west-2.console.aws.amazon.com/vpc/home

EC2 Management Console (select alternative region if necessary):
https://us-west-2.console.aws.amazon.com/ec2/v2/home
