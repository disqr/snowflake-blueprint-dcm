# Note the below that you need to specify the variables on the command line like so -D "test_value=my_test_value"
# In the yaml file...you need a corresponding:
# definition_version: 2
# #pass in general overall variables you will need here.
# env:
#   my_test_value: "this is a test"
snow sql --enable-templating JINJA -q "SELECT '{{test_value}}' AS TEST_VALUE;" -D "test_value=my_test_value"