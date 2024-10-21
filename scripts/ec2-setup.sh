#!/bin/bash

# Update the system
apt-get update -y
apt-get upgrade -y

# Install dependencies
apt-get install nginx -y

# Enable nginx
systemctl enable --now nginx
