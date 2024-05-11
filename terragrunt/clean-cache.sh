#!/bin/bash

find . -type d -name '.terragrunt-cache' | xargs rm -rf
find . -type f -name '.terraform.lock.hcl' -delete