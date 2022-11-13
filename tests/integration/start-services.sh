#!/usr/bin/env bash


function start_service() {
    # create the certificates
    sudo snap run opensearch.setup \
        --node-name cm0 \
        --node-roles cluster_manager,data \
        --tls-root-password root1234 \
        --tls-admin-password admin1234 \
        --tls-node-password node1234 \
        --tls-init-setup yes                 # this creates the root and admin certs as well.

    # system configs required by opensearch, can set one of the following ways:
    sysctl -w vm.max_map_count=262144

    # start opensearch
    sudo snap start opensearch.daemon
}

function create_index() {

    # create the security index
    sudo snap run opensearch.security-init --admin-password=admin1234

}

start_service

# wait a bit for it to fully initialize
sleep 5s

create_index

