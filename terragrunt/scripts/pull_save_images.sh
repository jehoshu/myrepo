#!/bin/bash
images=$(cat ecr_images)
lap() {
    local aws_profile=$1
    aws sso login --profile ${aws_profile}
    export AWS_PROFILE=${aws_profile}
}
lap $1
account_nmr=$(aws --profile $1 sts get-caller-identity | jq .Account | sed "s/\"//g")

aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $account_nmr.dkr.ecr.eu-west-1.amazonaws.com
#Get plugin images

while read image; do
    echo " 1 $image"
    read_name=$(echo $image | sed -r "s/-v([0-9])/:v\1/" | sed "s/\.tgz//g")
    docker pull $account_nmr.dkr.ecr.eu-west-1.amazonaws.com/$read_name
    docker save "$account_nmr.dkr.ecr.eu-west-1.amazonaws.com/$read_name" > "$image"
done < ecr_images

lap "ACCOUNT_NAME"
while read image; do
    aws s3 cp "$image" "s3://path of bucket name/$image"
done < ecr_images


# note that need to create txt file call ecr_images