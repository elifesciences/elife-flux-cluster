#!/bin/bash
set -e

tests_path="./tests"
while IFS=$' ' read -r resource state namespace name ; do
    if [[ "${resource:0:1}" == "#" ]]; then
        continue;
    fi
    if [[ $resource == "" ]]; then
        continue;
    fi
    kubectl wait "${resource}" --for=condition=${state} --timeout=10m -n ${namespace} ${name}
done < "$tests_path/resources_to_test.txt"
