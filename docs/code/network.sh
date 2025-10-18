#!/bin/bash
# Create resource groups
az group create -n rg-az104-hub -l westeurope
az group create -n rg-az104-app -l westeurope

# Create Hub VNet
az network vnet create -g rg-az104-hub -n vnet-hub --address-prefix 10.0.0.0/16 --subnet-name AzureBastionSubnet --subnet-prefix 10.0.1.0/24

# Create Spoke VNet
az network vnet create -g rg-az104-app -n vnet-app --address-prefix 10.1.0.0/16 --subnet-name app --subnet-prefix 10.1.1.0/24

# Peer Hub↔Spoke
az network vnet peering create -g rg-az104-hub -n hub-to-app --vnet-name vnet-hub --remote-vnet vnet-app --allow-vnet-access
az network vnet peering create -g rg-az104-app -n app-to-hub --vnet-name vnet-app --remote-vnet vnet-hub --allow-vnet-access

