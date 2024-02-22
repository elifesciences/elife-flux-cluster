#!/bin/bash

version="$1"

if [ -z "$version" ];
then
    echo "you must provide a node version to target for terminating"
    exit 1
fi

debug="echo "
debug=""

echo "This script will selectively drain/cordon each node, and then call aws-cli to terminate it after the cordoning has happened."
echo "it will paused after terminating to allow time for the node to come online, and termination to proceed."
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
    read -p "Proceed with draining? " proceed
    if [ ! "$proceed" == "y" ];
    then
        echo "terminated."
        exit 0;
    fi

    $debug kubectl drain --ignore-daemonsets $NodeName

    if [ $? -ne 0 ];
    then
        echo "Drain command didn't exit cleanly, review the output and decide next steps."
        read -p "Would you like to try draining again with --delete-emptydir-data? " proceed
        if [ "$proceed" == "y" ];
        then
            $debug kubectl drain --ignore-daemonsets --delete-emptydir-data $NodeName
        else
            echo "OK, but you must make sure the node is empty before terminating."
        fi
    fi

    read -p "Proceed with terminating? " proceed
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
