#!/bin/bash
# This script sets up the official Docker repository on an Ubuntu-based system.

echo "--- [Step 1/4] Updating package index and installing prerequisites ---"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

echo "--- [Step 2/4] Adding Docker's official GPG key ---"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "--- [Step 3/4] Setting up the Docker repository ---"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "--- [Step 4/4] Updating package index with the new repository ---"
sudo apt-get update

echo ""

echo "--- Setup complete! ---"
echo "You can now search for available Docker versions by running:"
echo "apt-cache madison docker-ce"
