## Docker docs - https://docs.docker.com/engine/install/ubuntu/ 

#### 1. Update System
```
sudo apt update && sudo apt upgrade -y
```
#### 2. Install Prerequisites
```
sudo apt install -y curl git apt-transport-https ca-certificates software-properties-common
```
#### 3. Install Docker
```
# Add Docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```
