#!/bin/bash

# This script takes input from the command line and applies the first buckets policy to the second bucket
# usage ./apply_policies.sh <bucket_to_copy_from> <bucket_being_copied_to>

funcApplyPolicy(){
    # Retrieves policy
    BASE_POLICY=`aws s3api get-bucket-policy --bucket $1`
    echo "Retreving Base Policy..."
    echo $BASE_POLICY

    # Extracts the policy value
    BASE_POLICY=`echo $BASE_POLICY | jq '.Policy'`
    echo "Extracting Policy.."
    echo $BASE_POLICY

    # Replaces name with needed SUFFIX/PREFIX
    NEW_POLICY=`echo $BASE_POLICY | sed 's/arn:aws:s3:::'''$1'''/arn:aws:s3:::'''$2'''/g'`
    echo "Replacing Suffix..."
    echo $NEW_POLICY

    # Strips first and last qoute
    NEW_POLICY=`sed -e 's/^"//' -e 's/"$//' <<<"$NEW_POLICY"`
    echo "Removing Qoutes..."
    echo $NEW_POLICY

    # Removes forward slashes to make it valid JSON
    NEW_POLICY=$(echo $NEW_POLICY | sed 's/\\//g')
    echo "Removing forward slashes..."
    echo $NEW_POLICY

    # Uploads policy to bucket
    echo "Uploading to Bucket..."
    aws s3api put-bucket-policy --bucket $2 --policy $NEW_POLICY

}


# Program Start
funcApplyPolicy $1 $2
