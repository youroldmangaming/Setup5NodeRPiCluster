#!/bin/bash

echo "# Check if the script is run as root"
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use 'sudo' or switch to root user."
    exit 1
fi

echo "Install GIT"
apt install git

# Variables
REPO_URL="https://github.com/youroldmangaming/Setup5NodeRPiCluster.git" # Change this to your repository URL
REPO_DIR="Setup" # Change this to your desired directory name if different
ENV_FILE="../.env"

echo "Step 1: Clone the repository"
git clone "$REPO_URL" "$REPO_DIR"

 

echo "# Step 2: Change into the repository directory"
cd "$REPO_DIR" || { echo "Failed to enter directory: $REPO_DIR"; exit 1; }
chmod 777 *

echo "Step 3: updates /etc/hosts"
cp hosts /etc/

echo "Run Scripts"
./share.sh
./slurm.sh
./docker
./keepalived.sh
./join.sh



# Step 3: Execute your scripts
# Step 3: Create .env file

#if [ -f "$ENV_FILE" ]; then

#    rm "$ENV_FILE" # Remove existing .env file

#fi

 

#echo "Enter the list of hosts and associated IPs (format: HOST=IP, one per line). Type 'done' when finished:"
#while true; do

 #   read -r line

  #  if [[ "$line" == "done" ]]; then

   #     break

    #fi

   # echo "$line" >> "$ENV_FILE"

#done


# Replace script1.sh and script2.sh with your actual script names

#if [ -f host.sh ]; then

#    chmod +x host.sh

#    ./host.sh

#else

#    echo "host.sh not found"
#fi


 

#if [ -f share.sh ]; then

 #   chmod +x share.sh

  #  ./share.sh

#else

 #   echo "share.sh not found"

#fi


#if [ -f slurm.sh ]; then

 #   chmod +x slurm.sh

  #  ./slurm.sh

#else

 #   echo "slurm.sh not found"

#fi



# Step 4: Exit the repository directory

#cd .. || exit 1

 

# Step 5: Remove the cloned repository

#rm -rf "$REPO_DIR"

 

echo "Script completed and repository removed."
