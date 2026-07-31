#!/bin/bash

# First run the below to create the needed dcm configuration in the snowflake account. This will create a role, grant the role to the 
# user who will run the dcm plan, and create the necessary database objects for dcm to operate. This only needs to be run once per account.
snow sql --filename setup.sql

