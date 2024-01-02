#!/bin/bash

mod=${1:-apply}

terraform $mod -var-file=test.tfvars -auto-approve
