
#/bin/bash

# This script creates buckets based on the suffix provided
# usage: ./create_buckets.sh <bucket_suffix>
# Example: ./create_buckets.sh sandbox

# VARIABLE LIST
BUCKET_SUFFIX=$1


# Function Definitions

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

echo "Creating buckets..."

# Modify the name of your buckets to use the appropriate names
aws s3api create-bucket --bucket plm-$BUCKET_SUFFIX.puppyspot.com --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
aws s3api create-bucket --bucket puppyspot-breeder-uploads-$BUCKET_SUFFIX --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
aws s3api create-bucket --bucket puppyspot-files-$BUCKET_SUFFIX --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
aws s3api create-bucket --bucket puppyspot-photos-$BUCKET_SUFFIX --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2

echo "Finished creating buckets"

echo "Syncing buckets..."

echo "Syncing plm-$BUCKET_SUFFIX.puppyspot.com"
aws s3 sync s3://plm-stage-01.puppyspot.com s3://plm-$BUCKET_SUFFIX.puppyspot.com
echo "Applying policy..."
funcApplyPolicy plm-stage-01.puppyspot.com plm-$BUCKET_SUFFIX.puppyspot.com

echo "Syncing puppyspot-breeder-uploads-$BUCKET_SUFFIX"
aws s3 sync s3://puppyspot-breeder-uploads-stage-01 s3://puppyspot-breeder-uploads-$BUCKET_SUFFIX
echo "Applying policy..."
funcApplyPolicy puppyspot-breeder-uploads-stage-01 puppyspot-breeder-uploads-$BUCKET_SUFFIX

echo "Syncing puppyspot-files-$BUCKET_SUFFIX"
aws s3 sync s3://puppyspot-files-stage-01 s3://puppyspot-files-$BUCKET_SUFFIX


echo "Syncing puppyspot-photos-$BUCKET_SUFFIX"
aws s3 sync s3://puppyspot-photos-stage-01 s3://puppyspot-photos-$BUCKET_SUFFIX
echo "Applying policy..."
funcApplyPolicy puppyspot-photos-stage-01 puppyspot-photos-$BUCKET_SUFFIX
