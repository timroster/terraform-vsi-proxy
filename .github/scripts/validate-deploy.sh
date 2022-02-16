#!/usr/bin/env bash

PUBLIC_IP=$(cat .public-ip)

echo "Private key"
cat .private-key

echo "Connecting to ssh server: ${PUBLIC_IP}"

ssh -o "StrictHostKeyChecking no" -i .private-key root@$(cat .public-ip) 'curl -x http://127.0.0.1:3128 http://example.com'
