#!/bin/bash

# Set parameters
ORG_ALIAS="ChangeMe"

echo ""
echo "Installing scratch org ($ORG_ALIAS)"
echo ""

echo "Setting x2od org as dev hub"
npm run devhub-x2od
echo ""

# Install script
echo "Cleaning previous scratch org..."
sf org delete scratch --no-prompt --target-org=$ORG_ALIAS &> /dev/null
echo ""

echo "Creating scratch org..." && \
sf org create scratch --set-default --definition-file config/project-scratch-def.json --duration-days 30 --alias $ORG_ALIAS && \
echo "" && \

echo "Pushing source..." && \
sf project deploy start&& \
echo "" && \

echo "Assigning permission sets..." && \
sf org assign permset --name perm_set_name && \
echo "" && \

echo "Importing sample data..." && \
sf data import tree --plan data/data-plan.json && \
echo "" && \

echo "Opening org..." && \
sf org open && \
echo ""

EXIT_CODE="$?"
echo ""

# Check exit code
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Installation completed."
else
    echo "Installation failed."
fi
exit $EXIT_CODE
