#!/usr/bin/env bash
set -e

# Skapa VMSS (använder SKU som oftast har kapacitet)
az vmss create \
  -g "$RG_APP" \
  -n "$VMSS_NAME" \
  --image Ubuntu2204 \
  --vm-sku Standard_B2s \
  --orchestration-mode Uniform \
  --instance-count 1 \
  --vnet-name "$VNET_APP" \
  --subnet "$SUBNET_APP" \
  --upgrade-policy-mode automatic \
  --admin-username azureuser --generate-ssh-keys \
  --lb "$LB_NAME" --backend-pool-name bepool \
  --custom-data <(cat <<'CLOUD'
#cloud-config
package_update: true
packages: [nginx]
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - bash -lc 'echo "AZ-104 demo via VMSS" > /var/www/html/index.nginx-debian.html'
CLOUD
)

# Hämta LB-IP
LB_IP=$(az network public-ip show -g "$RG_APP" -n lb-pip --query ipAddress -o tsv)
echo "Open http://$LB_IP"

