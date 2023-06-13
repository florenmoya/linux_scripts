#!/bin/bash

# Create Nginx site with HTTPS and PHP using Certbot.

# Get user input
read -p "Enter project name: " project_name
read -p "Enter domain name: " domain_name
read -p "Is this a staging site? (Y/N): " is_staging

# Set up variables
if [[ $is_staging =~ ^[Yy]$ ]]; then
  base_path="/staging/nodejs/"
  server_name="staging.${domain_name}.highlysucceed.com"
else
  base_path="/testing/nodejs/"
  server_name="develop.${domain_name}.highlysucceed.com"
fi

project_folder="${base_path}${project_name}"

# Check if project folder already exists
if [ -d "$project_folder" ]; then
  echo "Project folder already exists. Continuing with other tasks..."
else
  # Create project folder and clone repo
  cd "$base_path"
  git clone "git@bitbucket.org:hs-developers-2020/$project_name.git"
fi

# Create Nginx site configuration
cat > "/etc/nginx/sites-available/${server_name}" << EOF
server {
    server_name ${server_name};

    root ${project_folder}/build;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }
}
EOF

# Enable the site by creating a symbolic link
ln -s "/etc/nginx/sites-available/${server_name}" "/etc/nginx/sites-enabled/"

# Reload Nginx configuration
sudo systemctl reload nginx

# Install SSL/TLS certificate using Certbot
sudo certbot --nginx -d "${server_name}" -m "mjlemuel@highlysucceed.com" --agree-tos --non-interactive

# Display success message
echo "Nginx site for ${server_name} has been created at ${project_folder} with SSL/TLS certificate installed and HTTP traffic redirected to HTTPS."

cd "${base_path}${project_name}"

#fmoya

