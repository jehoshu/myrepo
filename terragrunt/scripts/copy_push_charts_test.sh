aws s3 cp s3://test-distribution-a1pw9hxg2byw/downstream/$1 /Josh/install_tmp/charts/ --endpoint https://s3.eu-west-1.amazonaws.com
helm push charts/$1 oci://harbor.Josh.test.int/stable/