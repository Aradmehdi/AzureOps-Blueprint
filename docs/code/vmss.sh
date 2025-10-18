#!/bin/bash
# Create VM Scale Set with Load Balancer
az vmss create \
  -g rg-az104-app \
  -n vmss-app \
  --image Ubuntu2204 \
  --upgrade-policy-mode automatic \
  --admin-username azureuser \
  --generate-ssh-keys \
  --vnet-name vnet-app \
  --subnet app \
  --lb lb-app

