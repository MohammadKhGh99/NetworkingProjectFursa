#!/bin/bash

# checks if the user gives the script the ip addres of the server
if [ $# -ne 1 ]; then
  echo "Please add the server ip as argument"
  exit 1
fi

CLIENT_HELLO='POST /clienthello {"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}'
curl
