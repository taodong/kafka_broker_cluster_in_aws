#!/bin/bash

mvn clean install -Dcloud.variable.config=src/kafka/cloud.json -Dcloud.variable.lookupFolder=src/kafka \
    -Dcloud.executor=terragrunt -Dcloud.assemble.root=src/kafka/aws \
    -Dcloud.terragrunt.arguments=destroy \
    -Dcloud.terragrunt.terraformVarFile=src/kafka/terraform.tfvars