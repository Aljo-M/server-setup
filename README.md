# server-setup

This is automatic script to setup server for production. 

git clone https://github.com/Aljo-M/server-setup.git

### Run the scrip
#### 1. Create a script file on server as root
```nano setup_server.sh```
Copy script inside and save. Ctrl + x, y, Enter.
#### 2. Make executable
```chmod +x setup_server.sh```
#### 3. Run
```./setup_server.sh
```
#### 4. Verify Everything Works
```# Try login as admin
ssh admin@YOUR_SERVER_IP

# Check firewal (only 22, 80 and 443 should be enabled)
sudo ufw status```



### Setup SSH connection
#### 1. Generate SSH keys on Your Local Machine:
```ssh-keygen -t rsa -b 4096```
#### 2. On the Server (as Root):
```mkdir -p /home/admin/.ssh
chmod 700 /home/admin/.ssh
```
#### 3. Copy the Public Key Manually:
```nano /home/admin/.ssh/authorized_keys```
#### 4. Set Correct Permissions:
```chmod 600 /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh
```
#### 5. Test SSH Login:
From your local machine, try logging in as admin:
```ssh admin@YOUR_SERVER_IP```
