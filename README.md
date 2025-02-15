# server-setup

This is automatic script to setup server for production. 


#### 1. Clone the repo
```
git clone https://github.com/Aljo-M/server-setup.git
cd server-setup
```
Copy script inside and save. Ctrl + x, y, Enter.
#### 2. Make executable
```
chmod +x server_setup.sh
```
#### 3. Run
```
./server_setup.sh
```
#### 4. Generate SSH keys on Your Local Machine:
```
ssh-keygen -t rsa -b 4096
```
#### 5. On the Server (as Root):
```
mkdir -p /home/admin/.ssh
chmod 700 /home/admin/.ssh
```
#### 6. Copy the Public Key Manually:
```
nano /home/admin/.ssh/authorized_keys
```
#### 7. Set Correct Permissions:
```
chmod 600 /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh
```
#### 8. Verify Everything Works (Setup SSH first)
```
# Try login as admin
ssh admin@YOUR_SERVER_IP

# Check firewal (only 22, 80 and 443 should be enabled)
sudo ufw status
```


## Install Docker - https://docs.docker.com/engine/install/ubuntu/ 

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
