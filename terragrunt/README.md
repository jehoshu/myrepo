Deployment automation
====================

This repo is a part of deployment automation.
used in AFT codepipline as a template for initialiation of customer's env.


## AFT pipeline
high level overview:
this pipeline runs at aft_account account. there are 4 pieplines

0. AFT repo as orechestarator of those below

1. account request

2. account provisioning custimaztions
3. global custimizations

4. account custimizations <- magic happens here

_account custimizations - AC_

each folder in this repository will fire-up and custimaztion pipeline for aws account.
the pipeline will parse dynamodb and export diffrent variables which will be used later.
also, this vairables will be stored in SSM parameter store and reused from this source.
those will pass using jinja to tf_run.sh

*tf_run.sh*

this script executing terragrunt run-all command to execute all terraform moudles and pass outputs as inputs.
state_bucket, acm, azure_ad_vpn_groups, bitbucket_repo, efs, export_parameters, security_groups, tgw_attachment, vpc, vpn_authorization.
then, runing bitbucket.sh 

*bitbucket.sh*

this script will collect difrrent enviroment variables from the AC pipeline.
will use a bucket for repository state and exports to SSM parameter store repository name.
then will clone repository gitops-template and manipluating it as followed:

_Branching_

will create and customer's repo 2 branches.

1. master will contain infrastrcute and so the folders : terraform, terragrunt

2. template will contain the application custimizations and will contain argocd and helm charts.

3. env will contain certificate the the new enviorment branch

## Jinja and folder manipulations
jinja folder is an temporery folder. the variables filled at AFT pipepline (bitbucket.sh script), files renamed and moved to the followed directories:

1. env.jinja -> ./terragurnt/<ENV>/env.hcl

2. terragrunt.jinja -> ./terragurnt/terragrunt.hcl

3. ./terragrunt/template -> ./terragrunt/<ENV>

## Phase 2
    This phase not yet included in the pipeline.
    In future after solving VPN automation connectivity problem,
    initialization will be completly automated as part of the AFT pipeline

_VPN_
to process it's importent to connect to network_account client VPN and the continue.
after connection cloning of account's repository should be preformed.
after cloning the repo, full-atuo.sh script should be runed as followd:
    env bash full-atuo.sh

    darwin_arm64 issue in template provider for those with m1 processoer.
    https://github.com/hashicorp/terraform/issues/27257#issuecomment-825102330

_full-auto.sh_
this script will preform the followed process in order:

1. preconfigure enviroment to continute (only vpn manualy pre-configured)

2. execution of the modules by order:
    parameters, eks, eks-argocd, vault

3. eks update-kubeconfig and switch contex to account's cluster

4. read ssh-key pair form SSM paramater store. if not exists, will search localy at ~/.ssh/$CUSTOMER_NAME/$CUSTOMER_NAME-$ENV_NAME-ops. if not exists will generate a pair and export them to SSM parameter store.

5. injection of private ssh key to eks cluster as a secret.

6. *Public key is now at your's clipboard, please manualy configure it as a key in customers repository*

7. execution of helm-rls moudle

8. vault procedure include initlaztion, upload of recovery keys and root token to parameter store. and follow the procedure explained here:
https://josh.atlassian.net/wiki/spaces/DE/pages/2050162689/HashiCorp+Vault+configuration

9. exection of the moudles:
    vault-secrets, argocd-init, elasticsearch, s3-archive
