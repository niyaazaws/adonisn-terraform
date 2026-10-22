# Terraform Project – EKS (Kubernetes) on AWS

## What it does
Builds a small Kubernetes cluster (EKS) in AWS with one command.

## Why we built it this way

- **Module** – the EKS code lives in `modules/capitec_eks`. Write it once, reuse it for dev, qa and prod.
- **Default VPC** – AWS already gives us a network with internet access. We just add our own subnets instead of building a whole network.
- **3 subnets in 3 zones** – EKS needs at least 2. If one zone goes down, the cluster keeps running.
- **Variables, no hardcoding** – instance type, ports, node count, CIDRs etc. are all inputs. Change a value, not the code.
- **Defaults** – things that rarely change (CIDRs, node count 1/3/1, version) have defaults, so you're only asked for what matters.
- **Naming** – everything is named `surname-initial-resource-env` (e.g. `adonis-n-eks-dev`) so you know who owns it and which environment it's in.
- **Tags in one place** – `locals.tf` holds the tags; the provider adds them to every resource automatically.
- **One file per environment** – `envs/dev`, `envs/qa`, `envs/prod` each have their own values and their own state, so dev changes can't break prod.
- **Remote state with locking** – state is saved in S3 (not on a laptop) and locked, so two people can't change it at the same time.
- **Outputs** – a summary at the end shows what was created.

## How to run

Quick test (prompts for values) – see `modules/capitec_eks/RunningTerraformPrompts.md`.

Real deploy (from this folder):
```bash
terraform init -reconfigure -backend-config=envs/dev/dev.tfbackend
terraform apply -var-file=envs/dev/dev.tfvars
```

Clean up when done (EKS costs money every hour):
```bash
terraform destroy -var-file=envs/dev/dev.tfvars
```
