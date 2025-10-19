AzureOps Blueprint

An end-to-end Azure lab environment built to demonstrate the core skills from AZ-104: Microsoft Azure Administrator.
This project simulates a mini enterprise cloud architecture that is secure, scalable, and cost-controlled.

Purpose

Showcase all core components covered in AZ-104.

Provide a reproducible demo environment for networking, compute, storage, monitoring, backup, governance, and cost management.

Serve as a portfolio project to highlight Azure administration and cloud operations skills.

 Architecture

Includes:

Hub–Spoke network topology with Azure Bastion for secure access.

VM Scale Set (VMSS) behind a Load Balancer serving a demo page.

Storage Account with Private Endpoint and Private DNS Zone.

Recovery Services Vault protecting workloads with backup.

Azure Monitor Alerts with Action Groups.

Azure Policy for compliance.

Azure Budget for cost governance.

📸 Architecture diagram:



azureops-blueprint/
│ README.md
│
├─ code/
│   ├─ 00_vars.sh         # Base variables
│   ├─ 10_network.sh      # Hub–Spoke + Bastion + Load Balancer
│   ├─ 20_vmss.sh         # VM Scale Set with NGINX demo
│   ├─ 30_storage.sh      # Storage + Private Endpoint + DNS
│   ├─ 40_backup.sh       # Recovery Services Vault + VM backup
│   ├─ 50_monitoring.sh   # Action Group + CPU Alert
│   ├─ 60_policy.sh       # Policy assignments
│   └─ 70_budget.sh       # Budget via ARM
│
└─ docs/
    └─ screenshots/
       hub-spoke.png
       bastion-login.png
       vmss-demo.png
       alerts.png
       storage-pe.png
       dns-zone.png
       backup.png
       policy.png
       budget.png


 Deployment Steps:
 
1. Load variables
source code/00_vars.sh

2. Networking (Hub–Spoke + Bastion + Load Balancer)
./code/10_network.sh


Validation: Check Network topology in the portal → hub and spoke are peered. Bastion is deployed.

3. Compute (VMSS + LB)
./code/20_vmss.sh


Validation:

curl http://<LB-IP>
# output: "AZ-104 demo via VMSS"

4. Storage with Private Endpoint + DNS
./code/30_storage.sh


Validation (from Bastion VM):

curl -I https://$SA.blob.core.windows.net
# returns 403/404 (good: DNS works, but requires auth)

5. Backup
./code/40_backup.sh


Validation: Portal → Recovery Services Vault → Backup items → VM listed.

6. Monitoring & Alerts
./code/50_monitoring.sh


Validation: Portal → Monitor → Alerts → Alert rules → CPU-high alert created.

7. Policy
./code/60_policy.sh


Validation: Try to deploy a resource without the required tag → deployment denied.

8. Budget
./code/70_budget.sh


Validation: Portal → Cost Management + Billing → Budgets → budget visible


Summary

AzureOps Blueprint demonstrates:

Secure network architecture with hub–spoke and Bastion.

Scalable workloads using VMSS + Load Balancer.

Secured storage with Private Endpoints and DNS.

Protected workloads with Backup.

Proactive monitoring & alerting.

Strong governance with Policy and Budget.

This project is a complete AZ-104 portfolio demo that can be used as a template for real-world enterprise Azure environments.
