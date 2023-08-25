#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as sudo."
  exit 1
fi


url="http://www.google.com"

# Check if the URL is reachable
if wget -q --spider "$url"; then
    echo "Internet connection is active."
else
    echo "Internet connection is not active."
    echo "Please connect to the Internet connection."
    exit 1
fi

echo "Welcome to the CICD Project Setup Script"
echo "---------------------------------------"
echo "This script will help you set up your environment for the CICD Project."

#echo "Updating package list..."
#sudo apt update

# Check if the user 'cicd' exists
# if id "cicd" &>/dev/null; then
#     echo "User cicd already exists."
# else
#     echo "Creating user cicd..."
#     sudo adduser cicd
# fi

NEW_USERNAME="cicd"
NEW_PASSWORD="cicdroot"

# Check if user exists
if id "$NEW_USERNAME" &>/dev/null; then
    echo "User $NEW_USERNAME already exists."
else
    # Create user
    useradd -m -s /bin/bash $NEW_USERNAME

    # Set password
    echo "$NEW_USERNAME:$NEW_PASSWORD" | chpasswd

    # Add user to sudoers
    echo "$NEW_USERNAME ALL=(ALL:ALL) ALL" >> /etc/sudoers

    echo "User $NEW_USERNAME created with sudo privileges."
fi

# # Check if user 'cicd' is already in the 'sudo' group
# if groups cicd | grep -q '\bsudo\b'; then
#     echo "User cicd is already in the sudo group."
# else
#     echo "Adding cicd to the sudo group..."
#     sudo usermod -aG sudo cicd
# fi

# # Check if sudo privileges have already been granted without a password
# if sudo grep -Eq '^cicd ALL=\(ALL:ALL\) NOPASSWD: ALL$' /etc/sudoers.d/cicd; then
#     echo "Sudo privileges are already granted to cicd without a password."
# else
#     echo "Granting sudo privileges to cicd without a password..."
#     echo "cicd ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/cicd
#     echo "User cicd has been set up with sudo privileges."
# fi


# Install Nginx without asking for user confirmation
install_nginx() {
    if ! command -v nginx &>/dev/null; then
        echo "Installing nginx..."
        sudo apt update
        sudo apt install nginx -y
        echo "Nginx has been installed."
    else
        echo "nginx is already installed."
    fi
}

# Install Git without asking for user confirmation
install_git() {
    if ! command -v git &>/dev/null; then
        echo "Installing git..."
        sudo apt update
        sudo apt install git -y
        echo "Git has been installed."
    else
        echo "git is already installed."
    fi
}

# Install Python without asking for user confirmation
install_python() {
    if ! command -v python3 &>/dev/null; then
        echo "Installing Python..."
        sudo apt update
        sudo apt install python3 -y
        echo "Python has been installed."
    else
        echo "Python is already installed."
    fi
}

# Install python3-pip without asking for user confirmation
install_python_pip() {
    if ! command -v pip3 &>/dev/null; then
        echo "Installing python3-pip..."
        sudo apt update
        sudo apt install python3-pip -y
        echo "python3-pip has been installed."
    else
        echo "python3-pip is already installed."
    fi
}

# Install python3-dev without asking for user confirmation
install_python_dev() {
    if [ ! -f /usr/include/python3.8/Python.h ]; then
        echo "Installing python3-dev..."
        sudo apt update
        sudo apt install python3-dev -y
        echo "python3-dev has been installed."
    else
        echo "python3-dev is already installed."
    fi
}

# Install virtualenv without asking for user confirmation
install_virtualenv() {
    if ! command -v virtualenv &>/dev/null; then
        echo "Installing virtualenv..."
        sudo apt update
        sudo apt install python3-pip -y
        sudo -H pip3 install virtualenv
        echo "virtualenv has been installed."
    else
        echo "virtualenv is already installed."
    fi
}

install_nginx
install_git
install_python
install_python_pip
install_python_dev
install_virtualenv


required_packages=(
    "requests"
    "logging"
    "json"
    "os"
    "tarfile"
    "shutil"
    "re"
    "datetime"
    "zipfile"
    "socket"
    "subprocess"
)

install_missing_packages() {
    missing_packages=()

    for package in "${required_packages[@]}"; do
        if ! python3 -c "import $package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "The following Python packages are missing and will be installed: ${missing_packages[*]}"
        pip install "${missing_packages[@]}"
        echo "Packages installed successfully."
    else
        echo "All required packages are already installed."
    fi
}


install_missing_packages

project_dir="/Project"

if [ -d "$project_dir" ]; then
    echo "Project directory already exists."
else
    mkdir "$project_dir"
    echo "Project directory created."
fi

repository_url="https://github.com/abhijitganeshshinde/CICD-Project.git"
destination_folder="/Project/CICD-Project"

if [ ! -d "$destination_folder" ]; then
    echo "Cloning repository..."
    echo "$repository_url"
    sudo git clone -b dev "$repository_url" "$destination_folder"
    echo "Repository cloned."
else
    echo "Repository folder already exists. Updating..."
    sudo git -C "$destination_folder" pull origin dev
    echo "Repository updated."
fi


config_file="$destination_folder/config.json"
read -p "Enter Access Token: " access_token
read -p "Enter Repository Owner: " repo_owner
read -p "Enter Repository Name: " repo_name
read -p "Enter Target Branch: " target_branch
read -p "Enter Deployment On: " deployment_on

json_data='{
    "RepositoriesDetail": [
        {
            "Access_Token": "'$access_token'",
            "Repository_Owner": "'$repo_owner'",
            "Repository_Name": "'$repo_name'",
            "CICD": [
                {
                    "Target_Branch": "'$target_branch'",
                    "Deployment_On": "'$deployment_on'"
                }
            ]
        }
    ]
}'


echo "$json_data" > "$config_file"
echo "JSON file updated."

deploymentcofig_file="$destination_folder/deploymentcofig.json"



echo "Select deployment configuration:"
echo "1. Default"
echo "2. Custom"
read deployment_choice


if [ "$deployment_choice" == "1" ]; then

    echo "Select project type:"
    echo "1. HTML"
    echo "2. Python"
    read project_type

    if [ "$project_type" == "1" ]; then
        programtype="index.html"
    elif [ "$project_type" == "2" ]; then
        programtype="app.py"
    else
        programtype="index.html"
    fi
    
    default_json='{
        "Nginx_Config_File_Location": "/etc/nginx/sites-available",
        "Nginx_Config_File": "default",
        "DeploymentDetails": [
            {
                "Repository_Name": "'$repo_name'",
                "Deploy": [
                    {
                        "Env": "QA",
                        "Target_Branch": "'$target_branch'",
                        "Location": "/var/www/qa",
                        "FolderName": "awesomeweb",
                        "Url": "qa-awesomeweb.local",
                        "MainFile": "'$programtype'"
                    }
                ]
            }
        ]
    }'


echo "$default_json" > "$deploymentcofig_file"
echo "Default deployment configuration applied."

elif [ "$deployment_choice" == "2" ]; then

    #read -p "Enter Repository Name: " repo_name
    read -p "Enter Environment: " env
    read -p "Enter Deployment On: " deployment_on
    #read -p "Enter Target Branch: " target_branch
    read -p "Enter Location: " location
    read -p "Enter Folder Name: " folder_name
    read -p "Enter URL: " url
    read -p "Enter Main File: " main_file
    

    custom_json='{
        "Nginx_Config_File_Location": "/etc/nginx/sites-available",
        "Nginx_Config_File": "default",
        "DeploymentDetails": [
            {
                "Repository_Name": "'$repo_name'",
                "Deploy": [
                    {
                        "Env": "'$env'",
                        "Target_Branch": "'$target_branch'",
                        "Location": "'$location'",
                        "FolderName": "'$folder_name'",
                        "Url": "'$url'",
                        "MainFile": "'$main_file'"
                    }
                ]
            }
        ]
    }'

    echo "$custom_json" > "$deploymentcofig_file"
    echo "Custom deployment configuration applied."

else
    echo "Invalid choice. Using default configuration."

    echo "Select project type:"
    echo "1. HTML"
    echo "2. Python"
    read project_type

    if [ "$project_type" == "1" ]; then
        programtype="index.html"
    elif [ "$project_type" == "2" ]; then
        programtype="app.py"
    else
        programtype="index.html"
    fi

    default_json='{
        "Nginx_Config_File_Location": "/etc/nginx/sites-available",
        "Nginx_Config_File": "default",
        "DeploymentDetails": [
            {
                "Repository_Name": "'$repo_name'",
                "Deploy": [
                    {
                        "Env": "dev",
                        "Target_Branch": "'$target_branch'",
                        "Location": "/var/www/dev",
                        "FolderName": "awesomeweb",
                        "Url": "dev-awesomeweb.local",
                        "MainFile": "'$programtype'"
                    }
                ]
            }
        ]
    }'

    echo "$default_json" > "$deploymentconfig_file"
    echo "Default deployment configuration applied."
fi


sudo chmod 777 /var/www
sudo chmod 777 /Project
sudo chmod 777 /etc/nginx/sites-available/default
sudo chmod 777 /etc/hosts
sudo chmod +x "$destination_folder/checknewcommit.py"
sudo chmod +x "$destination_folder/run_pythonprogram.sh"

bash_script_path="$project_dir/CICD-Project/run_pythonprogram.sh"
cron_expression="*/1 * * * *"

add_cron_job() {
    
    if crontab -l | grep -q "$bash_script_path"; then
        echo "Cron job already exists."
    else
        
        (crontab -l ; echo "$cron_expression  $bash_script_path") | crontab -
        echo "Cron job added successfully."
    fi
}

add_cron_job

sudo systemctl restart nginx
sudo systemctl restart cron

echo "Nginx and cron service restarted."

echo "Setup completed."
