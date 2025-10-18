#!/usr/bin/env bash
set -e

# Action Group (mail)
if ! az monitor action-group show -g "$RG_OPS" -n ag-email &>/dev/null; then
  az monitor action-group create -g "$RG_OPS" -n ag-email \
    --action email notify "$EMAIL_TO" >/dev/null
fi
AG_ID=$(az monitor action-group show -g "$RG_OPS" -n ag-email --query id -o tsv)

# CPU-alert på VMSS (stabilt via ARM)
VMSS_ID=$(az vmss show -g "$RG_APP" -n "$VMSS_NAME" --query id -o tsv)
ALERT_NAME="CPU-high"

BODY=$(cat <<EOF
{
  "location": "global",
  "properties": {
    "description": "Alert when VMSS average CPU > 80%",
    "severity": 3,
    "enabled": true,
    "scopes": ["$VMSS_ID"],
    "evaluationFrequency": "PT1M",
    "windowSize": "PT5M",
    "autoMitigate": true,
    "criteria": {
      "odata.type": "Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria",
      "allOf": [{
        "name": "CPUHigh",
        "criterionType": "StaticThresholdCriterion",
        "metricNamespace": "Microsoft.Compute/virtualMachineScaleSets",
        "metricName": "Percentage CPU",
        "timeAggregation": "Average",
        "operator": "GreaterThan",
        "threshold": 80,
        "dimensions": []
      }]
    },
    "actions": [{ "actionGroupId": "$AG_ID" }]
  }
}
EOF
)

az rest --method put \
  --uri "https://management.azure.com/subscriptions/$SUBID/resourceGroups/$RG_OPS/providers/microsoft.insights/metricAlerts/$ALERT_NAME?api-version=2018-03-01" \
  --headers "Content-Type=application/json" \
  --body "$BODY"

echo "Alert created: $ALERT_NAME (Monitor -> Alerts -> Alert rules)"

