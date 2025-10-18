#!/usr/bin/env bash
set -e

BUDGET_NAME="budget-az104"
AMOUNT="100"  # din valuta i subben
START=$(date +%Y-%m-01)                         # första dagen i denna månad
END=$(date -d "Dec 31" +%Y-%m-%d)               # årets slut
API="2025-07-01"

BODY=$(cat <<EOF
{
  "properties": {
    "category": "Cost",
    "amount": $AMOUNT,
    "timeGrain": "Monthly",
    "timePeriod": { "startDate": "$START", "endDate": "$END" },
    "notifications": {
      "Notify80Percent": {
        "enabled": true,
        "operator": "GreaterThan",
        "threshold": 80,
        "contactEmails": ["$EMAIL_TO"]
      }
    }
  }
}
EOF
)

# Subscription-scope budget
az rest --method put \
  --uri "https://management.azure.com/subscriptions/$SUBID/providers/Microsoft.Consumption/budgets/$BUDGET_NAME?api-version=$API" \
  --headers "Content-Type=application/json" \
  --body "$BODY"

echo "Budget created: $BUDGET_NAME ($AMOUNT / month, start=$START)"
