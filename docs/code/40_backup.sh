#!/usr/bin/env bash
set -e

# Skapa enkel VM utan publik IP för backup-demo
az vm create -g "$RG_APP" -n "$VM_BACKUP" \
  --image Ubuntu2204 \
  --size Standard_B1ms \
  --vnet-name "$VNET_APP" --subnet "$SUBNET_APP" \
  --public-ip-address "" \
  --admin-username azureuser --generate-ssh-keys

# Recovery Services Vault
az group create -n "$RG_OPS" -l "$LOC" --tags env=lab
az backup vault create -g "$RG_OPS" -n "$RSV_NAME" -l "$LOC"

# Skydda VM med default policy
az backup protection enable-for-vm \
  --vault-name "$RSV_NAME" -g "$RG_OPS" \
  --vm "$VM_BACKUP" -p "DefaultPolicy"

echo "Vault: $RSV_NAME, protected VM: $VM_BACKUP"

