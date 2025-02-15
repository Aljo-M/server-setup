# server-setup

This is automatic script to setup server for production. 


#### 0. Clone the repo
```
git clone https://github.com/Aljo-M/server-setup.git
cd server-setup
```
#### 1. Create a script file on server as root
```
nano setup_server.sh
```
Copy script inside and save. Ctrl + x, y, Enter.
#### 2. Make executable
```
chmod +x setup_server.sh
```
#### 3. Run
```
./setup_server.sh
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
