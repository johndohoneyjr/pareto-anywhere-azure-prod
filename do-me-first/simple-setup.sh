#!/usr/bin/env bash

# Environment Variables

export GITHUB_REPO="https://github.com/johndohoneyjr/pareto-anywhere-azure-prod"

export RESOURCE_GROUP="myiot-resources-$RANDOM"
export SERVICE_PRINCIPAL_NAME="pareto-serviceprincipal-$RANDOM"

echo "You must set the SUBSCRIPTION ID for your account, here is a table of available subscriptions..."
az account subscription list --query "[].{Name:displayName, ID:subscriptionId}" -o table
echo "Enter the subscription ID you wish to use..."
read MY_ID
export SUBSCRIPTION_ID=$MY_ID
echo ""
echo "You must set the location to place your resources, here is a table of available locations..."
echo ""
az account list-locations --query "[].{Name:displayName, RegionID:name}" -o table
echo "Enter the location you wish to use..."
read MY_LOCATION
export LOCATION=$MY_LOCATION

clear

if [[ -z "${SUBSCRIPTION_ID}" ]]; then
  clear
  az account subscription list --query "[].{Name:displayName, ID:subscriptionId}" -o table
  echo "Please set SUBSCRIPTION_ID to the account you wish to use"
  exit 1
else 
  echo "Using Subscription ID = $SUBSCRIPTION_ID for the following command set"
fi

if [[ -z "${RESOURCE_GROUP}" ]]; then
  clear
  echo "Please set RESOURCE_GROUP for the account you wish to use"
  exit 1
else 
  echo "Using Resource Group = $RESOURCE_GROUP for the following commands"
fi

if [[ -z "${LOCATION}" ]]; then
  clear
  echo "Please set LOCATION for the location you wish to use for set up, locations availaable..."
  az account list-locations --query [].metadata.pairedRegion[].name | sort
  exit 1
else 
  echo "Using Azure Region = $LOCATION for the following commands"
fi

if [[ -z "${SERVICE_PRINCIPAL_NAME}" ]]; then
  clear
  echo "Please set SERVICE_PRINCIPAL_NAME for the account you wish to use"
  exit 1
else 
  echo "Using Service Principal Name = $SERVICE_PRINCIPAL_NAME for the following commands"
fi

if [[ -z "${GITHUB_REPO}" ]]; then
  clear
  echo "Please set the GITHUB_REPO you wish to use to set the Service Principal as a secret"
  exit 1
else 
  echo "Using Github Repo = $GITHUB_REPO for GH Actions secrets"
fi

# Login to Owner account
echo ""
echo "Logging you into your account ..."
az login  --use-device-code

# Create the Resource Group
echo "Creating resource group - $RESOURCE_GROUP"
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "Creating Resource Group Scoped Service Principal..."
az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role Contributor --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP  --sdk-auth > gh-secret.json

# Authenticate to Github 

# This is to force a Github Login -- DONT Erase this :)
GITHUB_TOKEN=""
echo ""
echo "Logging into Github to set the service principal as a secret for Github actions automation.."
gh auth login

#
echo "Setting the Service Principal Github Secret for Github CodeSpaces ..."
gh secret set CLUSTER_SERVICE_PRINCIPAL -a codespaces -r $GITHUB_REPO < gh-secret.json

#
echo "Setting the Service Principal Github Secret for Github Actions automation..."
gh secret set CLUSTER_SERVICE_PRINCIPAL -r $GITHUB_REPO < gh-secret.json

if [ $? -eq 0 ]; then
   echo "Displaying the secret file...gh-secret.json, after you add ClientID and Secret, delete file..."
   cat ./gh-secret.json
else
   echo "You need to manually add the Service Principal with the label CLUSTER_SERVICE_PRINCIPAL to the Repo Secrets"
   echo "The JSON file is located in $PWD, and the file is gh-secret.json"
fi

echo "Setting Subscription ID Github Secret for Github Actions automation..."
gh secret set SUBSCRIPTION_ID -r $GITHUB_REPO --body "$SUBSCRIPTION_ID"
gh secret set SUBSCRIPTION_ID -a codespaces -r $GITHUB_REPO --body "$SUBSCRIPTION_ID"

echo "Setting Resource Group Name as Github Secret for Github Actions automation..."
gh secret set RESOURCE_GROUP -r $GITHUB_REPO --body "$RESOURCE_GROUP"
gh secret set RESOURCE_GROUP -a codespaces -r $GITHUB_REPO --body "$RESOURCE_GROUP"