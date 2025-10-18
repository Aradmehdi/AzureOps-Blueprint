#!/bin/bash
# =========================================================
# storage.sh - Create Storage Account with Private Endpoint
# For AZ-104 portfolio project
# =========================================================

# Variables
RG_APP="rg-az104-app"
LOC="westeurope"
SA_NAME="staz104$RANDOM"       # Storage account name must be unique
VNET_NAME="vnet-app"
SUBNET_NAME="app"
DNS_RG="rg-az104-hub"          # Where your DNS zone lives
DNS_ZONE="privatelink.blob.core.windows.net"

echo "Creating Storage Account: $SA_NAME in $RG_APP"

# Create storage account
az storage account create \
  -g $RG_APP \
  -n $SA_NAME \
  -l $LOC \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true

echo "Storage Account created: $SA_NAME"

# Create Private Endpoint
echo "Creating Private Endpoint for Blob service..."
az network private-endpoint create \
  -g $RG_APP \
  -n pe-$SA_NAME-blob \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --private-connection-resource-id $(az storage account show -n $SA_NAME -g $RG_APP --query id -o tsv) \
  --group-id blob \
  --connection-name peconn-$SA_NAME-blob

# Create Private DNS Zone if not exists
echo "Ensuring Private DNS Zone exists..."
az network private-dns zone create -g $DNS_RG -n $DNS_ZONE

# Link VNet to DNS Zone
echo "Linking VNet to Private DNS Zone..."
az network private-dns link vnet create \
  -g $DNS_RG \
  -n link-$VNET_NAME \
  -z $DNS_ZONE \
  -v $VNET_NAME \
  --registration-enabled false

# Create DNS record for storage account
echo "Adding DNS A-record for storage account..."
PE_IP=$(az network private-endpoint show -g $RG_APP -n pe-$SA_NAME-blob --query "customDnsConfigs[0].ipAddresses[0]" -o tsv)

az network private-dns record-set a add-record \
  -g $DNS_RG \
  -z $DNS_ZONE \
  -n $SA_NAME \
  -a $PE_IP

echo "Private Endpoint and DNS setup completed!"
echo "Test inside VNet: curl -I https://$SA_NAME.blob.core.windows.net"
