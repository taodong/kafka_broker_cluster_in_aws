#!/bin/bash -e

# This script will setup the environment of ec2 instance

REGION=$1
TYPE=$2

# Use type as private dns prefix
DNS_PREFIX=$TYPE

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Update the health.py to check correct service
if [[ -f "/usr/local/health/health.py" ]]; then
    sed -i.orig -e "s/\${SERVICE_NAME}/kafka/g" /usr/local/health/health.py
fi

# Upsert route53 record
IP=$(hostname -I)
NAME_TAG=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key, Values=Name" --region="$REGION" --output=text)
ZONE_ID=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key, Values=Zone" --region="$REGION" --output=text | cut -f 5)
DOMAIN_SUFFIX=$(aws route53 get-hosted-zone --id ${ZONE_ID} | grep Name | awk -F'"' '{print $4}' | sed 's/\.$//')

SERVER_ID=$(echo "$NAME_TAG" | rev | cut -d- -f1 | rev)
IFS='_' read -r -a ARR <<< "$SERVER_ID"

SERVER_TOTAL=${ARR[0]}
SERVER_INDEX=${ARR[1]}

DNS_ENTRY="${DNS_PREFIX}${SERVER_INDEX}.${DOMAIN_SUFFIX}"

echo "Updating $DNS_ENTRY to IP $IP in Zone ${ZONE_ID}"
sed -i.orig -e "s/\${dnsEntry}/$DNS_ENTRY/g" /tmp/routing.json
sed -i.orig -e "s/\${ip}/$IP/g" /tmp/routing.json

aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file:///tmp/routing.json

# sleep 5 minutes waiting for DNS ready
echo "sleep 5 minutes waiting for DNS ready"
sleep 300

# Update zookeeper and kafka config

if [[ -f /usr/local/kafka/config/zookeeper.properties ]]; then
    echo "Updating /usr/local/kafka/config/zookeeper.properties..."
    printf '\n' >> /usr/local/kafka/config/zookeeper.properties
    for i in $(seq "$SERVER_TOTAL"); do
	    echo "server.${i}=${DNS_PREFIX}${i}:2888:3888" >> /usr/local/kafka/config/zookeeper.properties
	    if [[ ${i} -ne 1 ]]; then
            ZOOKEEPER_LIST+=","
        fi
        ZOOKEEPER_LIST+="${DNS_PREFIX}${i}:2181"
    done
fi

echo "$SERVER_INDEX" > /var/zookeeper/myid

if [[ -f /usr/local/kafka/config/server.properties ]]; then
    echo "Updating /usr/local/kafka/config/server.properties..."
    sed -i.orig -e "s/\${BROKER_ID}/$SERVER_INDEX/g" /usr/local/kafka/config/server.properties
    sed -i.orig -e "s/\${ZOOKEEPER_LIST}/$ZOOKEEPER_LIST/g" /usr/local/kafka/config/server.properties
    sed -i.orig -e "s/\${SERVER_DNS}/$DNS_PREFIX$SERVER_INDEX/g" /usr/local/kafka/config/server.properties
fi

# Restart all necessary services
echo "Starting Zookeeper"
service zookeeper restart

echo "Starting Kfaka"
service kafka restart

echo "Starting HealthCheck"
service health-check restart
