#!/usr/bin/env bash
# Basvariabler för labben
export LOC="westeurope"
export RG_HUB="rg-az104-hub"
export RG_APP="rg-az104-app"
export RG_OPS="rg-az104-ops"
export VNET_HUB="vnet-hub"
export VNET_APP="vnet-app"
export SUBNET_APP="app"
export BASTION="bas-az104"
export LB_NAME="lb-web"
export VMSS_NAME="vmss-web"
export SA="staz104$RANDOM"                 # unikt storage-namn
export DNS_ZONE="privatelink.blob.core.windows.net"
export RSV_NAME="rsv-az104"
export VM_BACKUP="vm-backup"
export EMAIL_TO="you@example.com"          # <-- byt till din e-post
export SUBID=$(az account show --query id -o tsv)
echo "Loaded vars. Subscription=$SUBID"
