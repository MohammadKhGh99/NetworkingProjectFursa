#!/bin/bash

# checks if the user gives the script the ip addres of the server
if [ $# -ne 1 ]; then
  echo "Please add the server ip as argument"
  exit 1
fi

CLIENT_HELLO='{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}'

# get the json response from client hello POST request
SERVER_HELLO=$(curl -X POST -H "Content-Type: application/json" -d "$CLIENT_HELLO" "$1:8080/clienthello" | jq {"sessionID , serverCert"})

# save session ID in sessionID.txt file
echo "$SERVER_HELLO" | jq [".sessionID"] > "sessionID.txt"

# save serverCert in cert.pem file
echo "$SERVER_HELLO" | jq [".serverCert"] > "cert.pem"

# getting cert-ca-aws.pem file (aws CA certificate)
wget "https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem"

# verify the certificate
VERIFY_OUTPUT=$(openssl verify -CAfile cert-ca-aws.pem cert.pem)
if [ $? -ne 0 ]; then
  echo "Server Certificate is invalid"
  exit 5
else
  echo "$VERIFY_OUTPUT"
fi

rm -f cert-ca-aws.pem

# generate master key and save it in master-key.pem file
openssl rand -out master-key.pem 32

# encrypt the generated master-key secret with the server certificate
openssl smime -encrypt -aes-256-cbc -in master-key.pem -outform DER cert.pem | base64 -w 0

# send the encrypted master-key
SESSION_ID=$(cat sessionID.txt)
MASTER_KEY=$(cat master-key.pem)
SAMPLE_MSG="Hi server, please encrypt me and send to client!"
KEY_EXCH="{'sessionID': $SESSION_ID, 'masterKey': $MASTER_KEY, 'sampleMessage', '$SAMPLE_MSG'}"

# get the encrypted sample message from server
ENC_SAM_MSG=$(curl -X POST -H "Content-Type: application/json" -d "$KEY_EXCH" "$1:8080/keyexchange" | jq ".encryptedSampleMessage")

# decode the message
DEC_SAM_MSG=$(base64 -d "$ENC_SAM_MSG" | openssl enc -d -aes-256-cbc -pbkdf2 -k "$MASTER_KEY")
echo "Dec Message:"
echo "#DEC_SAM_MSG"
echo "Sample Message:"
echo "$SAMPLE_MSG"
# verify it
if [ "$DEC_SAM_MSG" == "$SAMPLE_MSG" ]; then
  echo "Client-Server TLS handshake has been completed successfully"
else
  echo "Server symmetric encryption using the exchanged master-key has failed."
  exit 6
fi

