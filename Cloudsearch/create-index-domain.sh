#!/bin/bash

# This script allows you to either create or index cloudsearch domains
# usage: ./create-index-domain.sh <INDEX or CREATE> <DOMAIN-NAME>
# example: ./create-index.domain.sh CREATE stage-01

# VARIABLE LIST

CHOICE=$1
DOMAIN_PREFIX=$2

# FUNCTION DEFINITIONS

funcApplyPolicy(){

    # Retriving Policy Object
    BASE_POLICY=`aws cloudsearch describe-service-access-policies --domain-name $1`

    # Pulling out policy string
    BASE_POLICY=`echo $BASE_POLICY | jq '.AccessPolicies.Options'`

    # Removing outer qoutes
    NEW_POLICY=`sed -e 's/^"//' -e 's/"$//' <<<"$BASE_POLICY"`

    # Removing forward slashes for proper JSON format
    NEW_POLICY=$(echo $NEW_POLICY | sed 's/\\//g')

    # Apply policy to new domain
    aws cloudsearch update-service-access-policies --domain-name $2 --access-policies $NEW_POLICY

}


if [ $CHOICE == "CREATE" ]
then

        echo "CREATING $DOMAIN_PREFIX-breeds"
        aws cloudsearch create-domain --domain-name "$DOMAIN_PREFIX-breeds"
    funcApplyPolicy stage-01-breeds $DOMAIN_PREFIX-breeds

        echo "CREATING $DOMAIN_PREFIX-external-listings"
        aws cloudsearch create-domain --domain-name "$DOMAIN_PREFIX-external-listings"
    funcApplyPolicy stage-01-external-listings $DOMAIN_PREFIX-external-listings

        echo "CREATING $DOMAIN_PREFIX-internal-listings"
        aws cloudsearch create-domain --domain-name "$DOMAIN_PREFIX-internal-listings"
    funcApplyPolicy stage-01-internal-listnings $DOMAIN_PREFIX-internal-listings

        echo "CREATING $DOMAIN_PREFIX-plm-listings"
        aws cloudsearch create-domain --domain-name "$DOMAIN_PREFIX-plm-listings"
    funcApplyPolicy stage-01-plm-listings $DOMAIN_PREFIX-plm-listings

elif [ $CHOICE == "INDEX" ]
then

        echo "INDEXING $DOMAIN_PREFIX-breeds"
        aws cloudsearch index-documents --domain-name "$DOMAIN_PREFIX-breeds"

        echo "INDEXING $DOMAIN_PREFIX-external-listings"
        aws cloudsearch index-documents --domain-name "$DOMAIN_PREFIX-external-listings"

        echo "INDEXING $DOMAIN_PREFIX-internal-listings"
        aws cloudsearch index-documents --domain-name "$DOMAIN_PREFIX-internal-listings"

        echo "INDEXING $DOMAIN_PREFIX-plm-listings"
        aws cloudsearch index-documents --domain-name "$DOMAIN_PREFIX-plm-listings"
else
        echo "You have chosen an incorrect option. Exiting."
fi
