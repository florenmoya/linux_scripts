#!/bin/bash

# Check if the script is run as root or with sudo privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

# Prompt for the username
read -p "Enter the username for the new account: " username

# Check if the username is provided
if [[ -z "$username" ]]; then
    echo "Username is required."
    exit 1
fi

# Check if the user already exists
if id "$username" >/dev/null 2>&1; then
    echo "User $username already exists."
    exit 1
fi

# Create the user account
sudo adduser --disabled-password --gecos "" "$username"

# Prompt for password
read -s -p "Enter the password for the new account: " password
echo

# Set the password for the new user
echo "$username:$password" | sudo chpasswd

# Create .ssh directory
sudo mkdir -p /home/"$username"/.ssh

# Prompt for public key
read -p "Enter the public key for SSH access: " public_key

# Add public key to authorized_keys file
echo "$public_key" | sudo tee -a /home/"$username"/.ssh/authorized_keys > /dev/null

# Set ownership and permissions
sudo chown -R "$username":"$username" /home/"$username"/.ssh
sudo chmod 700 /home/"$username"/.ssh
sudo chmod 600 /home/"$username"/.ssh/authorized_keys

# Print the account creation details
echo "User $username has been created successfully."
echo "Username: $username"
echo "Password: ********"
echo "Public key has been added to authorized_keys."
