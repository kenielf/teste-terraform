#!/bin/bash

# Update the system
apt-get update -y
apt-get upgrade -y

# Install dependencies
apt-get install nginx openssl fail2ban -y

# Configure nginx
cat <<EOL > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name example.com;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name example.com;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    location / {
        root /var/www/html;
        index index.html index.htm;
    }
}
EOL

mkdir /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=example.com"

# Configure fail2ban
cat <<EOL > /etc/fail2ban/jail.local
[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 600
EOL

# Enable services
systemctl enable --now nginx
systemctl enable --now fail2ban
