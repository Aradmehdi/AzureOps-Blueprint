#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# monitoring.sh - LAW + DCR + Association + Action Group + CPU Alert
# For AZ-104 portfolio project
# =========================================================

# --------- Vars (ändra vid behov) ----------
RG_OPS="${RG_OPS:-rg-az104-ops}"     # Ops/monitor-resurser
RG_APP="${RG_APP:-rg-az104-app}"     # Där VMSS ligger
LOC="${LOC:-westeurope}"
WORKSPACE_NAME="${WORKSPACE_NAME:-law-az104}"
DCR_NAME="${DCR_NAME:-dcr-az104}"
AG_NAME="${AG_NAME:-ag-email}"
ALERT_NAME="${ALERT_NAME:-CPU-high}"
ALERT_SEVERITY="${ALERT_SEVERITY:-3}"   # 0=Sev0 ... 4=Sev4
VMSS_NAME="${VMSS_NAME:-vmss-web}"
EMAIL_TO="${EMAIL_TO:-you@example.com}" # <-- byt till din e-post
# -------------------------------------------

echo ">> Using RG_OPS=$RG_OPS, RG_APP=$RG_APP, LOC=$LOC"
echo ">> Workspace=$WORKSPACE_NAME, DCR=$DCR_NAME, AG=$AG_NAME, VMSS=$VMSS_NAME, Email=$EMAIL_TO"

# 0) Förutsättningar
echo ">> Checking Azure CLI login/subscription..."
az account show -o none || az login >/dev/null

SUBID=$(az account show --query id -o tsv)

# 1) Log Analytics Workspace
if ! az monitor log-analytics workspace show -g "$RG_OPS" -n "$WORKSPACE_NAME" &>/dev/null; then
  echo ">> Creating Log Analytics Workspace..."
  az monitor log-analytics workspace create -g "$RG_OPS" -n "$WORKSPACE_NAME" -l "$LOC" >/dev/null
else
  echo ">> LAW already exists."
fi
WS_ID=$(az monitor log-analytics workspace show -g "$RG_OPS" -n "$WORKSPACE_NAME" --query id -o tsv)

# 2) Data Collection Rule (AMA) – samlar Perf + Syslog/Eventlog (basic)
if ! az monitor data-collection rule show -g "$RG_OPS" -n "$DCR_NAME" &>/dev/null; then
  echo ">> Creating Data Collection Rule..."
  az monitor data-collection rule create -g "$RG_OPS" -n "$DCR_NAME" --location "$LOC" \
    --data-flows '[{"streams":["Microsoft-Perf","Microsoft-Syslog"],"destinations":["la"]}]' \
    --destinations "[{\"workspaceResourceId\":\"$WS_ID\",\"name\":\"la\"}]" >/dev/null
else
  echo ">> DCR already exists."
fi
DCR_ID=$(az monitor data-collection rule show -g "$RG_OPS" -n "$DCR_NAME" --query id -o tsv)

# 3) Associera DCR till VMSS
echo ">> Associating DCR to VMSS..."
VMSS_ID=$(az vmss show -g "$RG_APP" -n "$VMSS_NAME" --query id -o tsv)
# Assoc-namn måste vara unikt per målresurs
ASSOC_NAME="dcra-$(echo "$VMSS_NAME" | tr '[:upper:]' '[:lower:]')"
if ! az monitor data-collection rule association show --association-name "$ASSOC_NAME" --resource "$VMSS_ID" &>/dev/null; then
  az monitor data-collection rule association create \
    --association-name "$ASSOC_NAME" \
    --resource "$VMSS_ID" \
    --rule-id "$DCR_ID" >/dev/null
else
  echo ">> DCR association already exists."
fi

# 4) Action Group (e-post)
if ! az monitor action-group show -g "$RG_OPS" -n "$AG_NAME" &>/dev/null; then
  echo ">> Creating Action Group $AG_NAME..."
  az monitor action-group create -g "$RG_OPS" -n "$AG_NAME" \
    --action email notify "$EMAIL_TO" >/dev/null
else
  echo ">> Action Group already exists."
fi
AG_ID=$(az monitor action-group show -g "$RG_OPS" -n "$AG_NAME" --query id -o tsv)

# 5) Metric Alert på VMSS CPU (>80% i 5 min) – via ARM (stabilt)
echo ">> Creating/Updating Metric Alert '$ALERT_NAME' on VMSS CPU..."
# Bygg alert JSON on-the-fly
ALERT_JSON=$(cat <<EOF
{
  "location": "global",
  "properties": {
    "description": "Alert when VMSS average CPU > 80%",
    "severity": $ALERT_SEVERITY,
    "enabled": true,
    "scopes": ["$VMSS_ID"],
    "evaluationFrequency": "PT1M",
    "windowSize": "PT5M",
    "autoMitigate": true,
    "criteria": {
      "odata.type": "Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria",
      "allOf": [
        {
          "name": "CPUHigh",
          "criterionType": "StaticThresholdCriterion",
          "metricNamespace": "Microsoft.Compute/virtualMachineScaleSets",
          "metricName": "Percentage CPU",
          "timeAggregation": "Average",
          "operator": "GreaterThan",
          "threshold": 80,
          "dimensions": []
        }
      ]
    },
    "actions": [
      { "actionGroupId": "$AG_ID" }
    ]
  }
}
EOF
)

# Använd en nylig, kompatibel API-version för metricAlerts
az rest --method put \
  --uri "https://management.azure.com/subscriptions/$SUBID/resourceGroups/$RG_OPS/providers/microsoft.insights/metricAlerts/$ALERT_NAME?api-version=2018-03-01" \
  --headers "Content-Type=application/json" \
  --body "$ALERT_JSON" >/dev/null

echo ">> Done."
echo "------------------------------------------------------------"
echo "LAW:            $WS_ID"
echo "DCR:            $DCR_ID"
echo "VMSS:           $VMSS_ID"
echo "Action Group:   $AG_ID"
echo "Alert rule:     $ALERT_NAME (CPU > 80%)"
echo "Check in Portal: Monitor -> Alerts -> Alert rules"
