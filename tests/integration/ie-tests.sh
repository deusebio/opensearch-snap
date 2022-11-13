#!/usr/bin/env bash

TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source ${TEST_DIR}/setup-dev-env.sh

source ${TEST_DIR}/start-services.sh

source ${TEST_DIR}/test-dev-cluster.sh

source ${TEST_DIR}/stop-services.sh
