#!/bin/bash

# This script creates an Nginx site with HTTPS and PHP using Certbot.

# Prompt the user for input
read -p "Enter the name of your project: " project_name
read -p "Enter your domain name: " domain_name
read -p "Is this a staging site? (Y/N): " is_staging
read -p "Enter the PHP version you would like to use (e.g., 7.4): " php_version

# Validate user input
if [ -z "$project_name" ] || [ -z "$domain_name" ] || [ -z "$php_version" ]; then
  echo "Error: Missing input. Please provide values for all required fields."
  exit 1
fi

if [[ "$is_staging" =~ ^[Yy]$ ]]; then
  base_path="/staging/php/"
  server_name="staging.${domain_name}.highlysucceed.com"
else
  base_path="/testing/php/"
  server_name="develop.${domain_name}.highlysucceed.com"
fi

project_folder="${base_path}${project_name}/public"

# Check if the project folder already exists
if [ -d "$project_folder" ]; then
  echo "Project folder already exists. Continuing with other tasks..."
else
  # Create project folder and clone the repository
  cd "$base_path"
  git clone "git@bitbucket.org:hs-developers-2020/$project_name.git"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to clone the repository. Please check your Git credentials and try again."
    exit 1
  fi
fi

# Create the Nginx site configuration
cat > "/etc/nginx/sites-available/${server_name}" << EOF
server {
    server_name ${server_name};

    index index.php index.html index.htm index.nginx-debian.html;

    root ${project_folder};

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
                try_files \$uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include fastcgi_params;
    }
}
EOF

# Enable the site by creating a symbolic link
ln -s "/etc/nginx/sites-available/${server_name}" "/etc/nginx/sites-enabled/"
if [ $? -ne 0 ]; then
  echo "Error: Failed to enable the Nginx site. Please check your Nginx configuration and try again."
  exit 1
fi

# Reload the Nginx configuration
sudo systemctl reload nginx

# Install an SSL/TLS certificate using Certbot
sudo certbot --nginx -d "${server_name}" -m "mjlemuel@highlysucceed.com" --agree-tos --non-interactive
if [ $? -ne 0 ]; then
  echo "Error: Failed to install the SSL/TLS certificate. Please check your Certbot configuration and try again."
  exit 1
fi

# Display a success message
echo "Nginx site for ${server_name} has been created at ${project_folder} with an SSL/TLS certificate installed, and HTTP traffic redirected to HTTPS. PHP version ${php_version} has been set for the site."

#

#MAINTAINED
#2.0
#FMOYA