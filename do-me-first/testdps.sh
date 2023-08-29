#! /bin/bash

# Set variables for the new IoT Hub, DPS, and enrollment group
resourceGroup="test-dps-settings"
location="westus2"
hubName="dohoney-west-hub"
dpsName="dohoney-west-dps"
enrollmentGroupName="dohoney-west-eg"

# Create a resource group
az group create --name $resourceGroup --location $location

# Create an IoT Hub
az iot hub create --resource-group $resourceGroup --name $hubName --sku S1

# Create a Device Provisioning Service
az iot dps create --name $dpsName --resource-group $resourceGroup --location $location

# Add an enrollment group that uses a symmetric key
az iot dps enrollment-group create --dps-name $dpsName --resource-group $resourceGroup --enrollment-id $enrollmentGroupName

# Get the primary key connection string for the IoT Hub
hubConnectionString=$(az iot hub show-connection-string --name $hubName --key primary --query connectionString -o tsv)

# Get the ID Scope for the DPS
dpsIdScope=$(az iot dps show --name $dpsName --resource-group $resourceGroup --query properties.idScope -o tsv)

# Display the primary key connection string and ID Scope
echo "IoT Hub primary key connection string: $hubConnectionString"
echo "DPS ID Scope: $dpsIdScope"
az iot dps policy show --dps-name $dpsName --resource-group $resourceGroup --policy-name provisioningserviceowner