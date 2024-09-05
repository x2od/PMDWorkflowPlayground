# UNMANAGED for use with developer edition or playground

# For use with developer edition or playground
echo "Pushing source..."
sf project deploy start --source-dir force-app/ChangeMe

echo "Assigning Permissions"
sf org assign permset --name perm_set_name

# To install additional sample Accounts/Contacts
# sf data import tree --plan ./data/data-plan.json

# To install sample data
echo "Adding sample data"
sf apex run --file ./data/sample-data.apex

# To install sample Flow and other metadata
echo "deploying sample metadata"
sf project deploy start --source-dir force-app/unmanaged

echo "opening org..."
sf org open