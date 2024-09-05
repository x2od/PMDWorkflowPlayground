npm run labsdevhub

echo "Cleaning previous scratch org..."
sf org delete scratch --no-prompt --target-org ChangeMe

echo "Creating new scratch org"
sf org create scratch --definition-file config/project-scratch-def.json --alias ChangeMe --set-default --no-ancestors --duration-days 21

# For use with non-namespaced scratch org in package development process
echo "Pushing managed metadata"
sf project deploy start --source-dir force-app/ChangeMe

echo "Deploy unmanaged metadata"
sf project deploy start --source-dir force-app/unmanaged

echo "Assigning permission set"
sf org assign permset --name perm_set_name

# To install sample data
echo "Loading sample data"
sf apex run --file ./data/sample-data.apex

echo "opening org"
sf org open --target-org ChangeMe