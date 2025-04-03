#!/bin/bash

version="$1"

if [ -z "$version" ];
then
    echo "you must provide a node version to target for terminating"
    exit 1
fi

debug="echo "
debug=""

echo "This script will selectively call aws-cli to terminate nodes."
echo "it will paused after terminating to allow you to control how quickly they are terminated"
echo ""
echo "---"
echo ""
echo "Current kubectl context is: $(kubectl config current-context)"

read -p "Is this the correct cluster? (y to proceed, anything else to exit) " proceed
if [ ! "$proceed" == "y" ];
then
    echo "terminated."
    exit 0;
fi
echo ""
echo "---"
echo ""

nodes=$(kubectl get node --sort-by=.metadata.name -o wide | grep $version | awk '{print $1}')

echo "nodes:"
echo "$nodes"
echo ""
echo "Number of nodes: $(echo $nodes | wc -w )"

read -p "Are these nodes OK to terminate? " proceed
if [ ! "$proceed" == "y" ];
then
    echo "terminated."
    exit 0;
fi

for NodeName in $nodes;
do
    export NodeInstanceId=$(kubectl get node $NodeName -o json | jq .spec.providerID -r - | cut -f 5 -d '/')
    echo ""
    echo "---"
    echo ""
    echo "Node Name: $NodeName"
    echo "AWS Instance Name: $NodeInstanceId"

    read -p "Proceed with force terminating? " proceed
    if [ ! "$proceed" == "y" ];
    then
        echo "terminated."
        exit 0;
    fi
    $debug aws ec2 terminate-instances --instance-ids=$NodeInstanceId

    echo "Paused processing to allow new node to arrive. "
    read -p "When ready, proceed with next node? " proceed
    if [ ! "$proceed" == "y" ];
    then
        echo "terminated."
        exit 0;
    fi
done

echo "All Done! "
echo ""
