#!/bin/bash

# To make this file runnable:
# $ chmod +x scripts/*.sh

echo "Set x2od org as dev hub"
npm run devhub-x2od

echo "Cleaning previous scratch org..."
sf org delete scratch --no-prompt --target-org=ChangeMe

echo "Creating new scratch org"
sf org create scratch --definition-file config/project-scratch-def.json --duration-days 10 --alias ChangeMe --set-default --no-namespace

echo "Pushing metadata"
sf project deploy start

#echo "Assigning Permissions"
#sf org assign permset --name PermSetName

echo "Adding sample data"
sf apex run --file ./data/data-plan.json

echo "opening org"
sf org open

echo "Org is set up"