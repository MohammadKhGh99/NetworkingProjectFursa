#!/bin/bash

if [ -z "${KEY_PATH}" ]; then
  echo "KEY_PATH env var is expected"
  exit 5
fi

if [ $# -eq 1 ]; then
  ssh -i "$KEY_PATH" ubuntu@$1
elif [ $# -eq 2 ]; then
  ssh -o StrictHostKeyChecking=accept-new -t -i "$KEY_PATH" ubuntu@$1 "ssh -i machine1.pem ubuntu@$2"
elif [ $# -eq 3 ];then
  ssh -o StrictHostKeyChecking=accept-new -i "$KEY_PATH" ubuntu@$1 "ssh -i machine1.pem ubuntu@$2 '$3'"
else
  echo "Please provide bastion IP address"
  exit 5
fi
