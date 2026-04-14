# OptScale Local VM Setup Guide

This guide explains how to provision a VM (on any supported cloud or bare metal), install Docker, configure SSH access to GitHub, clone the OptScale repository, and bring up the local Docker Compose stack.

---

## Prerequisites & Dependencies

Before starting, make sure you have the following:

- A provisioned VM running **Debian 12** (or compatible Linux distro)
- SSH access to the VM from your local machine
- Access to the target GitHub repository:
  - `git@github.com:yash2801murani/optscale-docker.git`
- The SSH private key file:
  - `~/.ssh/yash_murani_id`
- The matching public key already added to the `yash2801murani` GitHub account
- Enough disk space on the VM to build Docker images
  - Recommended: at least **50 GB**
- A machine type with enough CPU and memory for the stack
  - Recommended: **8 vCPUs / 32 GB RAM** or larger

---

## What This Setup Does

This process takes a freshly provisioned VM and prepares it to run the OptScale platform as a local Docker Compose stack.

The flow is:

1. **Provision a VM** (cloud-specific — pick your platform)
2. **Copy the SSH key** to the VM
3. Install Docker and Docker Compose
4. Configure GitHub SSH access
5. Clone the repository
6. Build the images locally
7. Start the stack with Docker Compose

---

## Phase 1 — Cloud VM Provisioning

Pick the section that matches your cloud provider. Each section covers creating the VM and copying the SSH key onto it. Once complete, skip to **Phase 2 — Common Setup**.

---

### Option A — AWS EC2

#### 1. Set environment variables

```bash
export AWS_REGION="us-east-1"
export INSTANCE_TYPE="m5.2xlarge"
export KEY_NAME="your-ec2-keypair"
export AMI_ID="ami-0a0e5d9c7acc336f1"   # Debian 12 in us-east-1; adjust per region
export SECURITY_GROUP="optscale-dev-sg"
export DISK_SIZE=50
export LOCAL_KEY="$HOME/.ssh/yash_murani_id"
```

#### 2. Create a security group

```bash
aws ec2 create-security-group \
  --group-name "$SECURITY_GROUP" \
  --description "OptScale dev VM"

aws ec2 authorize-security-group-ingress \
  --group-name "$SECURITY_GROUP" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-name "$SECURITY_GROUP" \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-name "$SECURITY_GROUP" \
  --protocol tcp --port 443 --cidr 0.0.0.0/0
```

#### 3. Launch the instance

```bash
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-groups "$SECURITY_GROUP" \
  --block-device-mappings "DeviceName=/dev/xvda,Ebs={VolumeSize=$DISK_SIZE,VolumeType=gp3}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=optscale-local-vm}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"
```

#### 4. Wait for the instance and get the public IP

```bash
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

EC2_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "VM IP: $EC2_IP"
```

#### 5. Copy the SSH key to the VM

```bash
scp -i ~/.ssh/"$KEY_NAME".pem "$LOCAL_KEY" admin@"$EC2_IP":~/.ssh/yash_murani_id
```

#### 6. SSH into the VM

```bash
ssh -i ~/.ssh/"$KEY_NAME".pem admin@"$EC2_IP"
```

*You are now on the VM. Proceed to Phase 2 — Common Setup.*

---

### Option B — Google Cloud (GCE)

#### 1. Set environment variables

```bash
export PROJECT_ID="project-dd78babb-fa69-4445-a5b"
export ZONE="us-central1-f"
export INSTANCE_NAME="optscale-local-vm"
export MACHINE_TYPE="e2-standard-8"
export DISK_SIZE="50GB"
export IMAGE_FAMILY="debian-12"
export IMAGE_PROJECT="debian-cloud"
export LOCAL_KEY="$HOME/.ssh/yash_murani_id"
```

#### 2. Create the VM

```bash
gcloud config set project "$PROJECT_ID"

gcloud compute instances create "$INSTANCE_NAME" \
  --project "$PROJECT_ID" \
  --zone "$ZONE" \
  --machine-type "$MACHINE_TYPE" \
  --boot-disk-size "$DISK_SIZE" \
  --boot-disk-type "pd-balanced" \
  --image-family "$IMAGE_FAMILY" \
  --image-project "$IMAGE_PROJECT" \
  --tags "optscale-dev"
```

#### 3. Open HTTP/HTTPS (optional)

```bash
gcloud compute firewall-rules create allow-optscale-http \
  --project "$PROJECT_ID" \
  --allow tcp:80,tcp:443 \
  --target-tags "optscale-dev" \
  --description "Allow HTTP/HTTPS to local OptScale stack" \
  --direction INGRESS \
  --priority 1000
```

#### 4. Copy the SSH key to the VM

```bash
gcloud compute scp "$LOCAL_KEY" "$INSTANCE_NAME:~/.ssh/yash_murani_id" \
  --zone "$ZONE" \
  --project "$PROJECT_ID" \
  --tunnel-through-iap
```

#### 5. SSH into the VM

```bash
gcloud compute ssh "$INSTANCE_NAME" --zone "$ZONE" --project "$PROJECT_ID"
```

*You are now on the VM. Proceed to Phase 2 — Common Setup.*

---

### Option C — Bare-Metal / Pre-Existing Debian VM

If you already have a Debian 12 VM (or any compatible machine) with SSH access, just copy the key and connect.

#### 1. Set environment variables

```bash
export VM_IP="<your-vm-ip>"
export VM_USER="<your-ssh-user>"
export LOCAL_KEY="$HOME/.ssh/yash_murani_id"
```

#### 2. Copy the SSH key to the VM

```bash
scp "$LOCAL_KEY" "$VM_USER@$VM_IP":~/.ssh/yash_murani_id
```

#### 3. SSH into the VM

```bash
ssh "$VM_USER@$VM_IP"
```

*You are now on the VM. Proceed to Phase 2 — Common Setup.*

---

## Phase 2 — Common Setup

Everything below runs on the VM. It does not matter which cloud you used — the steps are identical.

#### 1. Install Docker and Docker Compose

```bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release git openssh-client

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL [https://download.docker.com/linux/debian/gpg](https://download.docker.com/linux/debian/gpg) \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  [https://download.docker.com/linux/debian](https://download.docker.com/linux/debian) \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl restart docker
sudo usermod -aG docker "$USER"
```

> **Note:** Log out and back in (or run `newgrp docker`) so the group change takes effect.

**What this does:**
- Installs the packages needed for Docker and Git
- Adds Docker's official repository
- Installs Docker Engine and the Compose plugin
- Starts Docker and enables it on boot
- Adds the current user to the `docker` group

#### 2. Configure SSH for GitHub

```bash
set -euo pipefail

mkdir -p ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/yash_murani_id

cat > ~/.ssh/config <<'CFG'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/yash_murani_id
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
CFG

chmod 600 ~/.ssh/config
ssh-keyscan github.com >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts

ssh -T git@github.com || true
```

**What this does:**
- Sets correct permissions on the key file
- Tells SSH to use the correct key for GitHub
- Trusts GitHub's host key automatically the first time
- Tests authentication against GitHub

#### 3. Clone the repository

```bash
set -euo pipefail

mkdir -p ~/work
cd ~/work

if [ ! -d optscale-docker ]; then
  git clone git@github.com:yash2801murani/optscale-docker.git
fi

cd optscale-docker
git status
```

**What this does:**
- Creates a working directory
- Clones the repository only if it is not already present
- Confirms the repo is clean and ready

#### 4. Prepare the environment file

```bash
set -euo pipefail

cd ~/work/optscale-docker

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi
```

**What this does:**
- Creates the `.env` file used by Docker Compose
- Preserves sane defaults for local development

#### 5. Build and start the stack

```bash
set -euo pipefail

cd ~/work/optscale-docker

make build
make up
```

**What this does:**
- Builds the Docker images from the local Dockerfiles
- Starts the complete stack in detached mode
- Brings up the databases, backend services, frontend, and gateway

---

## Verification

#### 1. Docker is installed

```bash
docker --version
docker compose version
```
*Both commands should print version information with no permission errors.*

#### 2. GitHub SSH access works

```bash
ssh -T git@github.com
```
*GitHub should confirm the authenticated account.*

#### 3. Containers are running

```bash
cd ~/work/optscale-docker
docker compose ps
```
*Core services should show `Up`. Database containers should be `healthy`. `nginx` and `ngui` should be running if the full stack is up.*

#### 4. UI is accessible

Open the VM's external IP in a browser:

```text
http://<VM_EXTERNAL_IP>/
```

How to find the IP depends on your cloud:

| Cloud | Command |
| :--- | :--- |
| **AWS** | `aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text` |
| **GCP** | `gcloud compute instances describe optscale-local-vm --zone us-central1-f --format='get(networkInterfaces[0].accessConfigs[0].natIP)'` |
| **Bare-metal** | Use the IP you already have |

#### 5. Logs

If something is not starting, inspect the service logs:

```bash
cd ~/work/optscale-docker
docker compose logs --tail=200
docker compose logs --tail=200 nginx ngui restapi auth
```

**What to look for:**
- Database readiness failures
- Missing environment variables
- SSH or Git clone issues
- Backend service startup errors

---

## Recommended Cleanup

If you copied the private SSH key to the VM, remove it after setup:

```bash
rm -f ~/.ssh/yash_murani_id
```

*Keep the private key only on trusted machines when possible.*

---

## Summary

After completing these steps, you will have:

- A VM sized for the OptScale stack (on any supported cloud or bare metal)
- Docker and Docker Compose installed
- GitHub SSH authentication configured
- The repository cloned on the VM
- The application stack running locally in Docker Compose

This is the standard onboarding path for local infrastructure development and smoke testing.
