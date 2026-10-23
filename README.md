# Terraform Project – EKS (Kubernetes) on AWS

## What it does
Builds a small Kubernetes cluster (EKS) in AWS for **dev**, **qa** and **prod**. Each environment is separate: its own state, its own subnets, its own cluster.

## Folder layout
```
bootstrap/state-buckets/   # run once first - creates the S3 buckets that hold the state
bootstrap/github-oidc/     # run once - lets GitHub Actions log in to AWS (optional)
modules/capitec_eks/       # the EKS code (written once, used by every environment)
modules/capitec_s3/        # the state bucket code (used by bootstrap/state-buckets)
envs/dev|qa|prod/          # <env>.tfvars = values, <env>.tfbackend = where the state lives
main.tf, variables.tf      # root - calls the EKS module with the env's values
locals.tf, providers.tf    # tags + AWS provider + backend
safety.tf                  # stops dev values being applied to prod state (and vice versa)
k8s/nginx.yaml             # test app to prove the cluster works
```

## Why we built it this way
- **Module** – the EKS code lives in `modules/capitec_eks`. Write it once, reuse it for dev, qa and prod.
- **Default VPC** – AWS already gives us a network with an internet gateway and routes. We just add our own subnets instead of building a whole network.
- **3 subnets in 3 zones** – EKS needs at least 2. If one zone goes down, the cluster keeps running.
- **Variables, no hardcoding** – instance type, ports, node count, CIDRs etc. are all inputs. Change a value, not the code.
- **Defaults** – things that rarely change (CIDRs, node count 1/3/1, version) have defaults, so you're only asked for what matters.
- **Naming** – everything is named `surname-initial-resource-env` (e.g. `adonis-n-eks-dev`) so you know who owns it and which environment it's in.
- **Tags in one place** – `locals.tf` holds the tags; the provider adds them to every resource automatically.
- **One folder per environment** – `envs/dev`, `envs/qa`, `envs/prod` each have their own values and their own state, so dev changes can't break prod.
- **Outputs** – a summary at the end shows what was created.

## How environments differ (on purpose)

| | dev | qa | prod |
|---|---|---|---|
| Node size | t3.small (cheap) | t3.medium | t3.large (more CPU/memory) |
| Nodes min/max/desired | 1/3/1 | 1/3/1 | 1/3/1 |
| Subnets | 172.31.160–162.0/24 | 172.31.170–172.0/24 | 172.31.180–182.0/24 |
| State versioning | off (throwaway) | on | on |

Subnet ranges never overlap, so all three can run at the same time in the same VPC.

## Remote state (how it works)
- Each environment has **its own S3 bucket**: `adonisn-s3-dev`, `adonisn-s3-qa`, `adonisn-s3-prod`.
- Each bucket holds one state file: `<env>/terraform.tfstate`.
- **Locking:** `use_lockfile = true` – Terraform puts a lock file next to the state while it runs, so two people can't change the same environment at once (needs Terraform 1.10+, no DynamoDB needed).
- **Encrypted** (`encrypt = true`) and **public access blocked** – state can contain sensitive values.
- **Versioning** on qa/prod – if a state file gets broken, you can restore an older copy.
- The `backend "s3" {}` block in `providers.tf` is empty on purpose. The real settings come from `envs/<env>/<env>.tfbackend` at `init` time – that's what picks the environment.

### The chicken-and-egg problem (bootstrapping)
The state buckets must exist **before** the project can store state in them. So they're created separately in `bootstrap/state-buckets`, which uses **local** state. Run it once:
```bash
cd bootstrap/state-buckets
terraform init
terraform apply
```
Keep its `terraform.tfstate` safe (it's not committed). If it's lost, the buckets still work – you'd just import them to manage them again.

## How to deploy each environment
Run from the project root. Swap `dev` for `qa` or `prod`.

```bash
# 1. Point Terraform at the dev state
terraform init -reconfigure -backend-config=envs/dev/dev.tfbackend

# 2. See what will change
terraform plan -var-file=envs/dev/dev.tfvars

# 3. Build it
terraform apply -var-file=envs/dev/dev.tfvars
```

Then see `How-to-access-EKS.md` to connect and open nginx.

**Always** run `init -reconfigure` when switching environment – that's what swaps the state file.

Clean up when done (EKS costs money every hour):
```bash
terraform destroy -var-file=envs/dev/dev.tfvars
```

Quick test without the backend (prompts for values) – see `modules/capitec_eks/RunningTerraformPrompts.md`.

## Safety: can't mix up environments
`safety.tf` checks that the state you initialised matches the `environment` in your tfvars.
If you `init` with prod but plan with `dev.tfvars`, the plan stops with:
```
Backend state 'prod/terraform.tfstate' does not match environment 'dev'.
```
Nothing is changed. Fix it by running `init -reconfigure` with the right `.tfbackend`.

## Evidence
Each environment planned on its own, against its own state bucket (account ID blanked out):
- `evidence/plan-dev.txt` – dev: 14 to add, `adonis-n-eks-dev`, t3.small
- `evidence/plan-qa.txt` – qa: 14 to add, `adonis-n-eks-qa`, t3.medium
- `evidence/plan-prod.txt` – prod: 14 to add, `adonis-n-eks-prod`, t3.large
- `evidence/safety-guard.txt` – prod state + dev values = blocked

dev was also applied end to end (cluster ACTIVE, nginx reachable on port 30007), then destroyed. Everything has been torn down so nothing costs money.

## Assumptions, trade-offs and limitations
- **Default VPC** – assumes the account has one (it does in af-south-1). Simpler and cheaper, but all environments share one VPC; separation is by subnet, not by network.
- **Public subnets, no NAT gateway** – nodes get public IPs so they can reach the internet. Saves the NAT cost (~$30+/month each) but is less secure than private subnets. For real prod, use private subnets + NAT.
- **NodePort open to the internet** – port 30007 allows `0.0.0.0/0` so nginx is easy to test. Lock `nodeport_allowed_cidrs` down to your IP for anything real.
- **Cluster API is public** – fine for training; restrict it for real use.
- **Same account for all environments** – real companies usually use a separate AWS account per environment.
- **Safety guard** reads `.terraform/terraform.tfstate` (written by `init`). It's a simple guard, not a lock – a person can still deliberately bypass it.
- **CI pipeline** (`.github/workflows/terraform.yml`) applies all environments on push to `main` and needs AWS credentials as GitHub secrets. It's not set up on this repo, so those jobs fail safely without touching AWS.
- **Bootstrap state is local** – one person/laptop owns the state buckets' own state.
