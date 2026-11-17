#!/bin/bash

source .env
sed -e "s|\${ACCOUNT_ID}|$ACCOUNT_ID|g" \
    -e "s|\${DEPLOYER_ROLE}|$DEPLOYER_ROLE|g" \
    -e "s|\${DEPLOYER_USER}|$DEPLOYER_USER|g" \
    manifest.template.yml > manifest.yml

# command made ready for cmdline
sed -e "s|\${ACCOUNT_ID}|$ACCOUNT_ID|g" -e "s|\${DEPLOYER_ROLE}|$DEPLOYER_ROLE|g" -e "s|\${DEPLOYER_USER}|$DEPLOYER_USER|g" manifest.template.yml > manifest.yml



# comment in the below for snowflake setup
#####################################
# First run the below to create the needed dcm configuration in the snowflake account. This will create a role, grant the role to the 
# user who will run the dcm plan, and create the necessary database objects for dcm to operate. This only needs to be run once per account.
# snow sql --filename setup.sql
# snow dcm plan
