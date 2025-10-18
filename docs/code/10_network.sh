#!/usr/bin/env bash
set -e

# Resource Groups
az group create -n "$RG_HUB" -l "$LOC" --tags env=lab
az group create -n "$RG_APP" -l "$LOC" --tags env=lab

# Hub VNet + Bastion-subnät
az network vnet create -g "$RG_HUB" -n "$VNET_HUB" \
  --address-prefix 10.0.0.0/16 \
  --subnet-name AzureBastionSubnet --subnet-prefix 10.0.0.0/27

# Spoke VNet + app-subnät
az network vnet create -g "$RG_APP" -n "$VNET_APP" \
  --address-prefix 10.1.0.0/16 \
  --subnet-name "$SUBNET_APP" --subnet-prefix 10.1.0.0/24

# Peering båda håll
az network vnet peering create -g "$RG_HUB" -n hub-to-app \
  --vnet-name "$VNET_HUB" \
  --remote-vnet "/subscriptions/$SUBID/resourceGroups/$RG_APP/providers/Microsoft.Network/virtualNetworks/$VNET_APP" \
  --allow-vnet-access

az network vnet peering create -g "$RG_APP" -n app-to-hub \
  --vnet-name "$VNET_APP" \
  --remote-vnet "/subscriptions/$SUBID/resourceGroups/$RG_HUB/providers/Microsoft.Network/virtualNetworks/$VNET_HUB" \
  --allow-vnet-access

# Bastion
az network public-ip create -g "$RG_HUB" -n pip-bastion --sku Standard
az network bastion create -g "$RG_HUB" -n "$BASTION" \
  --public-ip-address pip-bastion \
  --vnet-name "$VNET_HUB" \
  --location "$LOC"

# Load Balancer (Standard) i app-RG
az network lb create -g "$RG_APP" -n "$LB_NAME" --sku Standard \
  --frontend-ip-name fe --backend-pool-name bepool \
  --public-ip-address lb-pip --public-ip-sku Standard

# Health probe + regel 80/TCP
az network lb probe create -g "$RG_APP" --lb-name "$LB_NAME" -n http-probe --protocol Tcp --port 80
az network lb rule create -g "$RG_APP" --lb-name "$LB_NAME" -n http-80 \
  --protocol Tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name fe --backend-pool-name bepool --probe-name http-probe

echo "Network + Bastion + LB done."
