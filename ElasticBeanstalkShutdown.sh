#!/bin/bash

### Constants ###

STATUS_AVAILABLE="available"
STATUS_STOPPED="stopped"
HEALTH_GREY="Health: Grey"

### Autoscaling Groups ###
API_STAGE_01_AG_GROUP="awseb-e-4hmwiwgz2x-stack-AWSEBAutoScalingGroup-1P9EUSRG6XYGU"
API_STAGE_02_AG_GROUP="awseb-e-tgnp8evtfd-stack-AWSEBAutoScalingGroup-1TS5G5Z29WI2X"
API_STAGE_03_AG_GROUP="awseb-e-mzwdqipnsm-stack-AWSEBAutoScalingGroup-17GKN3OO14L70"
API_STAGE_04_AG_GROUP="awseb-e-6q2axhqz2c-stack-AWSEBAutoScalingGroup-KE1RONJOKRYM"
API_ENG_01_AG_GROUP="awseb-e-4esgtjzpay-stack-AWSEBAutoScalingGroup-111B9TQ4ZRVET"
API_ENG_02_AG_GROUP="awseb-e-fndzm3eets-stack-AWSEBAutoScalingGroup-1BEYNTK9JHG50"

CC_STAGE_01_AG_GROUP="awseb-e-jjdtfcjsxm-stack-AWSEBAutoScalingGroup-1SWQ2I1P2OIDU"
CC_STAGE_02_AG_GROUP="awseb-e-spzg9bzpkw-stack-AWSEBAutoScalingGroup-1QW70HSHV1YON"
CC_STAGE_03_AG_GROUP="awseb-e-wwvgu9jmjd-stack-AWSEBAutoScalingGroup-9YEBIR1ICR0C"
CC_STAGE_04_AG_GROUP="awseb-e-3cybiqpsar-stack-AWSEBAutoScalingGroup-102JTVN3LYKJP"
CC_ENG_01_AG_GROUP="awseb-e-jpmchpa3pw-stack-AWSEBAutoScalingGroup-D1RX5EYHFAIK"
CC_ENG_02_AG_GROUP="awseb-e-ppe2ew2kdx-stack-AWSEBAutoScalingGroup-1NUP7LH4I9DF6"

CCENTER_STAGE_01_AG_GROUP="awseb-e-3feqtmik5c-stack-AWSEBAutoScalingGroup-I84S3TVABBSS"
CCENTER_STAGE_02_AG_GROUP="awseb-e-k6p3pahrs7-stack-AWSEBAutoScalingGroup-MMH2UUOU94R5"
CCENTER_STAGE_03_AG_GROUP="awseb-e-hf3us9qgxn-stack-AWSEBAutoScalingGroup-D89BMOA1PR40"
CCENTER_STAGE_04_AG_GROUP="awseb-e-fmvupejkbm-stack-AWSEBAutoScalingGroup-1CIUVXU4NXXHH"
CCENTER_ENG_01_AG_GROUP="awseb-e-bx43yc9prq-stack-AWSEBAutoScalingGroup-O6J6LC3U7W9N"
CCENTER_ENG_02_AG_GROUP="awseb-e-9cnmdd3ned-stack-AWSEBAutoScalingGroup-FOMBFUQZ1H5K"

CONSUMER_STAGE_01_AG_GROUP="awseb-e-2chr89vmpd-stack-AWSEBAutoScalingGroup-1106FZZF6I4KC"
CONSUMER_STAGE_02_AG_GROUP="awseb-e-pdhdmyk27b-stack-AWSEBAutoScalingGroup-T3VFWPITI0KV"
CONSUMER_STAGE_03_AG_GROUP="awseb-e-n7pmwpppix-stack-AWSEBAutoScalingGroup-ZYFYERYRMIR5"
CONSUMER_STAGE_04_AG_GROUP="awseb-e-qjpxxyumng-stack-AWSEBAutoScalingGroup-1C8OQNDPO3IJQ"
CONSUMER_ENG_01_AG_GROUP="awseb-e-mnsqxrdtab-stack-AWSEBAutoScalingGroup-1SPNRE54Y2JJ9"
CONSUMER_ENG_02_AG_GROUP="awseb-e-pc39gdi3sc-stack-AWSEBAutoScalingGroup-196R2KLLSLGV8"

LEGACY_STAGE_01_AG_GROUP="awseb-e-vhg7dt6ksx-stack-AWSEBAutoScalingGroup-4Y6O2SVZBJJ6"
LEGACY_STAGE_02_AG_GROUP="awseb-e-ppng4pvhpp-stack-AWSEBAutoScalingGroup-JK4LS3PEO5JK"
LEGACY_STAGE_03_AG_GROUP="awseb-e-smg4c3tzsj-stack-AWSEBAutoScalingGroup-V7DCC3343X0F"
LEGACY_STAGE_04_AG_GROUP="awseb-e-wk6ruc8pky-stack-AWSEBAutoScalingGroup-DJUGPR48Y8N"
LEGACY_ENG_01_AG_GROUP="awseb-e-pvshspqmpq-stack-AWSEBAutoScalingGroup-1245R7GPOYOK4"
LEGACY_ENG_02_AG_GROUP="awseb-e-ekgepuvbyv-stack-AWSEBAutoScalingGroup-3JLIZYT9SY1Q"



### FUNCTION LIST ###

function waitForRdsStatus {
    instance=$1
    target_status=$2
    status="unknown"
    echo -n "Starting up RDS server..."
    while [[ "$status" != "$target_status" ]]; do
        status="$(aws rds describe-db-instances --db-instance-identifier ${instance} | jq -r '.DBInstances[].DBInstanceStatus')"
        sleep 5
    done
}


function waitForEbStatus {
    instance=$1
    target_status=$2
    
    status="unknown"
    while [[ "'$status'" != "'$target_status'" ]]; do
	    status="$(eb status ${instance} | grep "$target_status" | xargs)"
        sleep 5
    done
}


function shutDownDatabase {
    instance=$1
    
    status="$(aws rds describe-db-instances --db-instance-identifier ${instance} | jq -r '.DBInstances[].DBInstanceStatus')"
    if [ $status == $STATUS_AVAILABLE ]; then
       stdout_fix="$(aws rds stop-db-instance --db-instance-identifier ${instance})"
    fi
}




function shutDownEnvironment {
    curr=$(date -u +%Y-%m-%d-%H:%M:%S)
    delay=$(date -d "($curr) +1minutes" -u +%Y-%m-%d-%H:%M:%S)
    environment=$1
    full_environment=$2
    autoscaling_group_name=$3
    

	init_name=$environment
    if [ "${environment}" == "api" ]; then
        init_name="pbbapi"
    fi 
    
    if [ "${environment}" == "worker" ]; then
        init_name="pbbapi"
    fi 
    
    if [ "${environment}" == "cc" ]; then
        init_name="pbbapi"
    fi

    if [ "${environment}" == "ccenter" ]; then
        init_name="CCenter"
    fi
    
    if [ "${environment}" == "consumer" ]; then
        init_name="consumer"
    fi
    
    if [ "${environment}" == "legacy" ]; then
        init_name="legacy"
    fi
    
    echo "3" | eb init $init_name --region us-west-2
    eb use $full_environment
    if eb status $full_environment | grep -q "Health: Green"; then
      	echo "The Environment, ${full_environment}, is UP. It will now be brought down.  Please allow 10 minutes to shutdown..."
        if [ ! -z $autoscaling_group_name ]; then
            echo "We are now shutting down ${full_environment}"
            aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name $autoscaling_group_name --scheduled-action-name one-time-shutdown --start-time $delay --min-size 0 --max-size 0 --desired-capacity 0
        
            echo "Waiting for ${full_environment} to shut down..."
            waitForEbStatus ${full_environment} "$HEALTH_GREY"
        else
            echo "${full_environment} is NOT Ready. Aborting~\n";
        fi
    fi

}



### PROGRAM START ###


echo -n "Shutting down Environments..."


shutDownEnvironment api API-Stage-01 ${API_STAGE_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-stage-01

shutDownEnvironment api API-Stage-02 ${API_STAGE_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-stage-02

shutDownEnvironment api API-Stage-03 ${API_STAGE_03_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-stage-03

shutDownEnvironment api API-Stage-04 ${API_STAGE_04_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-stage-04

shutDownEnvironment api API-Eng-01 ${API_ENG_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-eng-01

shutDownEnvironment api API-Eng-02 ${API_ENG_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-eng-02

shutDownEnvironment cc CC-Stage-01 ${CC_STAGE_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-stage-01

shutDownEnvironment cc CC-Stage-02 ${CC_STAGE_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-stage-02

shutDownEnvironment cc CC-Stage-03 ${CC_STAGE_03_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-stage-03

shutDownEnvironment cc CC-Stage-04 ${CC_STAGE_04_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-stage-04

shutDownEnvironment cc CC-Eng-01 ${CC_ENG_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-eng-01

shutDownEnvironment cc CC-Eng-02 ${CC_ENG_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase api-eng-02

shutDownEnvironment ccenter CCenter-Stage-01 ${CCENTER_STAGE_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase ccenter-stage-01

shutDownEnvironment ccenter CCenter-Stage-02 ${CCENTER_STAGE_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase ccenter-stage-02

shutDownEnvironment ccenter CCenter-Stage-03 ${CCENTER_STAGE_03_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase ccenter-stage-03

shutDownEnvironment ccenter CCenter-Stage-04 ${CCENTER_STAGE_04_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase ccenter-stage-04

shutDownEnvironment ccenter CCenter-Eng-01 ${CCENTER_ENG_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase ccenter-eng-01

shutDownEnvironment ccenter CCenter-Eng-02 ${CCENTER_ENG_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase ccenter-eng-02

shutDownEnvironment consumer Consumer-Stage-01 ${CONSUMER_STAGE_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase consumer-stage-01

shutDownEnvironment consumer Consumer-Stage-02 ${CONSUMER_STAGE_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase consumer-stage-02

shutDownEnvironment consumer Consumer-Stage-03 ${CONSUMER_STAGE_03_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase consumer-stage-03

shutDownEnvironment consumer Consumer-Stage-04 ${CONSUMER_STAGE_04_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase consumer-stage-04

shutDownEnvironment consumer Consumer-Eng-01 ${CONSUMER_ENG_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase consumer-eng-01

shutDownEnvironment consumer Consumer-Eng-02 ${CONSUMER_ENG_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase consumer-eng-02

shutDownEnvironment legacy Legacy-Stage-01 ${LEGACY_STAGE_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase legacy-stage-01

shutDownEnvironment legacy Legacy-Stage-02 ${LEGACY_STAGE_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase legacy-stage-02

shutDownEnvironment legacy Legacy-Stage-03 ${LEGACY_STAGE_03_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase legacy-stage-03

shutDownEnvironment legacy Legacy-Stage-04 ${LEGACY_STAGE_04_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase legacy-stage-04

shutDownEnvironment legacy Legacy-Eng-01 ${LEGACY_ENG_01_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase legacy-eng-01

shutDownEnvironment legacy Legacy-Eng-02 ${LEGACY_ENG_02_AG_GROUP}

echo "Shutting down database..."
shutDownDatabase legacy-eng-02
