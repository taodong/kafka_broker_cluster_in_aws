#!/bin/bash

mvn clean install -Dcloud.variable.config=src/kafka/cloud.json -Dcloud.variable.lookupFolder=src/kafka \
    -Dcloud.executor=packer -Dcloud.assemble.root=src/kafka/ami -Dcloud.assemble.extra=src/shared