#!/bin/bash

# check if the user has added KEY_PATH env var
if [ -z "${KEY_PATH}" ]; then
  echo "KEY_PATH env var is expected"
  exit 5
fi

# we have jus one argument that is just the ip address of the public instance
if [ $# -eq 1 ]; then
  ssh -o StrictHostKeyChecking=accept-new -i "$KEY_PATH" ubuntu@$1
# have two arguments, one for ip address of the public instance and the other for ip address of the private instance
elif [ $# -eq 2 ]; then
  ssh -o StrictHostKeyChecking=accept-new -t -i "$KEY_PATH" ubuntu@$1 "ssh -i private_key.pem ubuntu@$2"
# we have 3 arguments, two as above and the third one for a command to run in private instance
elif [ $# -eq 3 ];then
  ssh -o StrictHostKeyChecking=accept-new -i "$KEY_PATH" ubuntu@$1 "ssh -i private.pem ubuntu@$2 '$3'"
# if there is no arguments given
else
  echo "Please provide bastion IP address"
  exit 5
fi
