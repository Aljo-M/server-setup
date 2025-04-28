# Production-Ready Ubuntu 24.04 → Docker → Kubernetes Setup Index

## 1. System Preparation & Hardening

_Establish a secure OS baseline with patching, CIS compliance, SSH, firewall, and AppArmor._

- **1.1 Update & Unattended Upgrades** — Apply all security patches and enable automatic updates.
- **1.2 CIS Benchmark Automation** — Enforce Ubuntu Security Guide profiles for CIS compliance.
- **1.3 SSH Hardening** — Disable root and password logins, restrict users, and change the SSH port.
- **1.4 Firewall (UFW)** — Set default deny for incoming traffic and allow only SSH.
- **1.5 AppArmor & Cleanup** — Remove unused services and ensure AppArmor profiles are enforced.
- **1.6 MFA for SSH** — Enforce multi-factor authentication for SSH access.

## 2. Docker Installation & Hardening

_Install and secure Docker with namespace isolation, seccomp, and logging._

- **2.1 Official Repo Installation** — Add Docker GPG key, apt repository, and install Docker CE.
- **2.2 Daemon Configuration** — Enable user namespace remapping, log rotation, and disable legacy registry.
- **2.3 Runtime Security** — Enforce seccomp and AppArmor profiles, and restrict the Docker API socket.
- **2.4 Log Management** — Configure JSON-file logging with size and rotation limits.
- **2.5 Image Security Scanning** — Scan Docker images for vulnerabilities using Trivy or Anchore before deployment.

## 3. Kubernetes (kubeadm) Setup & Hardening

_Bootstrap a secure Kubernetes cluster with HA, API/Kubelet lockdown, and network policies._

- **3.1 Package Installation** — Add Kubernetes apt repo, install and hold kubelet, kubeadm, and kubectl.
- **3.2 Control Plane Bootstrap** — Initialize the cluster with kubeadm, specifying CIDR and uploading TLS certs.
- **3.3 High Availability & etcd** — Choose between stacked or external etcd architectures for HA.
- **3.4 API Server & Kubelet Hardening** — Enable audit logging, set secure flags, and disable read-only ports.
- **3.5 Network Policies** — Deploy Calico or Cilium for Pod network isolation.
- **3.6 RBAC & Pod Security** — Enforce least-privilege roles and baseline/strict Pod security standards.
- **3.7 Dashboard Security** — Secure the Kubernetes Dashboard with RBAC and avoid public exposure.

## 4. Users, Permissions & SSH Keys

_Manage users and access with least-privilege principles and key-based authentication._

- **4.1 Admin User & Groups** — Create a deployer user and add to the sudo group.
- **4.2 Sudoers Least Privilege** — Configure NOPASSWD for only Docker and kubectl commands.
- **4.3 SSH Key Deployment** — Store keys in `~/.ssh/authorized_keys` and disable password authentication.
- **4.4 SSH Key Rotation** — Enforce periodic regeneration and redeployment of SSH keys.

## 5. Production Tooling

_Set up observability, logging, backups, and secrets management for production._

- **5.1 Monitoring & Alerting** — Deploy Prometheus and Grafana with node-exporter and Alertmanager.
- **5.2 Logging** — Implement EFK stack or Grafana Loki for centralized log management.
- **5.3 Backups & DR** — Schedule etcd snapshots via etcdctl cron and Velero for PV backups.
- **5.4 Alerting Configuration** — Define Prometheus alerting rules for critical metrics and incidents.
- **5.5 Secrets Management** — Use HashiCorp Vault or encrypted Kubernetes Secrets for sensitive data.

## 6. Automation & Partitioning

_Automate infrastructure and configuration with IaC, CM, and modular scripts._

- **6.1 Infrastructure as Code** — Use Terraform for provisioning VMs, VPCs, and load balancers.
- **6.2 Configuration Management** — Apply Ansible or idempotent Bash roles for system configuration.
- **6.3 Modular Script Phases** — Organize scripts into phases (e.g., 00-bootstrap.sh, 10-docker.sh, 20-k8s.sh).
- **6.4 Namespace & Cluster Segmentation** — Isolate logging/monitoring from workloads using namespaces.
- **6.5 Version Control** — Manage all automation scripts and configurations in a Git repository.

## 7. Maintainability & Ongoing Security

_Ensure long-term system health with CI/CD, upgrades, autoscaling, and audits._

- **7.1 GitOps & CI/CD** — Validate scripts with ShellCheck and apply changes via CI/CD pipelines.
- **7.2 Canary & Rolling Upgrades** — Use blue/green deployments, cluster-autoscaler, and Kured for reboots.
- **7.3 Autoscaling & Patch Management** — Enable Cluster Autoscaler and perform staged rollouts.
- **7.4 Periodic CIS Audits** — Rerun Ubuntu Security Guide profiles and update AppArmor/seccomp quarterly.
- **7.5 Network Segmentation** — Isolate infrastructure components to reduce the impact of breaches.
- **7.6 Vulnerability Management** — Regularly scan and remediate vulnerabilities across the stack.
- **7.7 Backup Validation** — Periodically test restore procedures for etcd and Velero backups.
- **7.8 Penetration Testing** — Conduct regular security assessments to identify weaknesses.
- **7.9 Security Training** — Train staff on secure operations and awareness of emerging threats.
