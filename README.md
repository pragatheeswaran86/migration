
# GCP Organization + VPC + GKE Starter

This repo provisions:
- **Organization & IAM** (folders, service accounts, roles)
- **Billing linkage**
- **Custom VPC** with subnets & secondary ranges
- **Cloud NAT** for private GKE nodes
- **Firewall rules**
- **GKE cluster** (Workload Identity enabled)

Includes GitHub Actions workflows for:
- Terraform init/plan/apply
- OIDC authentication to GCP (Workload Identity Federation)

## Steps
1. Configure Workload Identity Federation for GitHub → GCP.
2. Add secrets in GitHub:
   - `PROJECT_ID`, `ORG_ID`, `BILLING_ACCOUNT`
   - `WIF_PROVIDER`, `WIF_SERVICE_ACCOUNT`
3. Run Terraform workflow.
