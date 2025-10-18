#!/usr/bin/env bash
set -e

RG_TARGET="$RG_APP"
TAG_NAME="env"

# Hämta built-in policy-id via display name
POLICY_ID=$(az policy definition list \
  --query "[?displayName=='Require a tag on resources'].id | [0]" -o tsv)

az policy assignment create \
  -g "$RG_TARGET" \
  -n require-env-tag \
  --policy "$POLICY_ID" \
  --params "{ \"tagName\": { \"value\": \"$TAG_NAME\" } }"

echo "Policy assigned on RG=$RG_TARGET (Require tag: $TAG_NAME)"
