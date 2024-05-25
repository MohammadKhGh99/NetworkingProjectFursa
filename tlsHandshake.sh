#!/bin/bash

# checks if the user gives the script the ip address of the server
if [ $# -ne 1 ]; then
  echo "Please add the server ip as argument"
  exit 1
fi

SERVER_IP=$1
CONTENT_TYPE="Content-Type: application/json"

CLIENT_HELLO='{
   "version": "1.3",
   "ciphersSuites": [
      "TLS_AES_128_GCM_SHA256",
      "TLS_CHACHA20_POLY1305_SHA256"
   ],
   "message": "Client Hello"
}'

# get the json response from client hello POST request
SERVER_HELLO=$(curl -s -X POST -H "$CONTENT_TYPE" -d "$CLIENT_HELLO" "$SERVER_IP":8080/clienthello | jq {"sessionID , serverCert"})
if [ $? -ne 0 ]; then
  echo "client hello request failed"
  exit 1
fi

# save session ID in variable
SESSION_ID=$(echo "$SERVER_HELLO" | jq -r ".sessionID")
if [ $? -ne 0 ]; then
  echo "server hello response json does not contain 'sessionID' key"
  exit 1
fi

# save serverCert in cert.pem file
echo  "$SERVER_HELLO" | jq -r ".serverCert" > "cert.pem"
if [ $? -ne 0 ]; then
  echo "server hello response json does not contain 'serverCert' key"
  exit 1
fi

# getting cert-ca-aws.pem file (aws CA certificate)
wget -q "https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem"
if [ $? -ne 0 ]; then
  echo "getting cert-ca-aws.pem file failed"
  exit 1
fi

# verify the certificate
VERIFY_OUTPUT=$(openssl verify -CAfile cert-ca-aws.pem cert.pem)
if [ $? -ne 0 ]; then
  echo "Server Certificate is invalid"
  exit 5
else
  echo "$VERIFY_OUTPUT"
fi


# generate master key and save it in master-key.pem file
openssl rand -base64 32 > master-key.pem
if [ $? -ne 0 ]; then
  echo "failed to make master key"
  exit 1
fi

# encrypt the generated master-key secret with the server certificate
ENC_MASTER=$(openssl smime -encrypt -aes-256-cbc -in master-key.pem -outform DER cert.pem | base64 -w 0)
if [ $? -ne 0 ]; then
  echo "master key encryption failed"
  exit 1
fi

# send the encrypted master-key
#SESSION_ID=$(cat sessionID.txt)
MASTER_KEY=$(cat master-key.pem)
SAMPLE_MSG="Hi server, please encrypt me and send to client!"
KEY_EXCH="{\"sessionID\": \"$SESSION_ID\", \"masterKey\": \"$ENC_MASTER\", \"sampleMessage\": \"Hi server, please encrypt me and send to client!\"}"

# get the encrypted sample message from server
#curl -X POST -H "Content-Type: application/json" -d "$KEY_EXCH" "$1:8080/keyexchange"
ENC_MSG=$(curl -s -X POST -H "Content-Type: application/json" -d "$KEY_EXCH" "$SERVER_IP":8080/keyexchange | jq -r ".encryptedSampleMessage")
if [ $? -ne 0 ]; then
  echo "getting the encrypted sample message failed"
  exit 1
fi

# decode the message
DEC_SAM_MSG=$(echo "$ENC_MSG" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$MASTER_KEY")
# verify it
if [ "$DEC_SAM_MSG" == "$SAMPLE_MSG" ]; then
  echo "Client-Server TLS handshake has been completed successfully"
else
  echo "Server symmetric encryption using the exchanged master-key has failed."
  exit 6
fi

rm -f cert-ca-aws.pem* cert.pem master-key.pem
