#!/bin/bash

# the user should add ip address as the only argument
if [ $# -ne 1 ]; then
  echo "Add ip address of private instance"
  exit 1
fi

# checks if the old key exists
if [ -e private_key.pem ]; then
  mv private_key.pem old_key.pem
  mv private_key.pem.pub old_key.pem.pub
fi

# generate new key-pair
ssh-keygen -t rsa -b 2048 -f private_key.pem -N ""
# copy the public key to authorized_keys in private ec2
cat private_key.pem.pub | ssh -o StrictHostKeyChecking=accept-new -i old_key.pem ubuntu@$1 "cat > ~/.ssh/authorized_keys"
# remove old key
rm -f old_key.pem old_key.pem.pub