#!/usr/bin/env bash
set -e

echo "Creating storage account: $SA"
az storage account create \
  -g "$RG_APP" -n "$SA" -l "$LOC" \
  --sku Standard_LRS --kind StorageV2 --https-only true

SA_ID=$(az storage account show -g "$RG_APP" -n "$SA" --query id -o tsv)

# Skapa Private Endpoint i app-subnät
az network private-endpoint create \
  -g "$RG_APP" \
  -n "pe-$SA-blob" \
  --vnet-name "$VNET_APP" \
  --subnet "$SUBNET_APP" \
  --private-connection-resource-id "$SA_ID" \
  --group-id blob \
  --connection-name "peconn-$SA-blob"

# Skapa Private DNS zon + länk + DNS zone group (auto A-records)
az network private-dns zone create -g "$RG_APP" -n "$DNS_ZONE" --query id -o tsv >/dev/null
az network private-dns link vnet create \
  -g "$RG_APP" -n "link-$VNET_APP" \
  -z "$DNS_ZONE" -v "$VNET_APP" --registration-enabled false

# Knyt PE till DNS-zonen (zone group)
PE_ID=$(az network private-endpoint show -g "$RG_APP" -n "pe-$SA-blob" --query id -o tsv)
az network private-endpoint dns-zone-group create \
  --endpoint-name "pe-$SA-blob" \
  --name "zonegrp-$SA-blob" \
  --resource-group "$RG_APP" \
  --private-dns-zone "$DNS_ZONE" \
  --zone-name "privatelink" >/dev/null

echo "Test inside VM via Bastion: curl -I https://$SA.blob.core.windows.net"
