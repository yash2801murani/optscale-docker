# OptScale Local VM Setup Guide

This guide explains how to provision a Google Cloud VM, install Docker, configure SSH access to GitHub, clone the OptScale repository, and bring up the local Docker Compose stack.

## Prerequisites & Dependencies

Before starting, make sure you have the following:

- A Google Cloud project with billing enabled
- Permission to create VM instances in that project
- The `gcloud` CLI installed locally and authenticated
- Access to the target GitHub repository:
  - `git@github.com:yash2801murani/optscale-docker.git`
- The SSH private key file:
  - `~/.ssh/yash_murani_id`
- The matching public key already added to the `yash2801murani` GitHub account
- A local machine with internet access
- Enough disk space on the VM to build Docker images
  - Recommended: at least `50GB`
- A machine type with enough CPU and memory for the stack
  - Recommended: `e2-standard-8` or larger

## What This Setup Does

This process creates a fresh Google Cloud VM and prepares it to run the OptScale platform as a local Docker Compose stack.

The flow is:

1. Create a VM on GCP
2. Install Docker and Docker Compose
3. Configure GitHub SSH access
4. Clone the repository
5. Build the images locally
6. Start the stack with Docker Compose

## Step-by-Step Guide

### 1. Set the environment variables

These variables make the commands reusable and reduce mistakes.

```bash
export PROJECT_ID="project-dd78babb-fa69-4445-a5b"
export ZONE="us-central1-f"
export INSTANCE_NAME="optscale-local-vm"
export MACHINE_TYPE="e2-standard-8"
export DISK_SIZE="50GB"
export IMAGE_FAMILY="debian-12"
export IMAGE_PROJECT="debian-cloud"
export REPO_SSH="git@github.com:yash2801murani/optscale-docker.git"
export LOCAL_KEY="$HOME/.ssh/yash_murani_id"
```

### 2. Create the VM

This command provisions a new GCP VM with enough resources for the full Dockerized stack.

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

What this does:

- `gcloud config set project` selects the active GCP project
- `compute instances create` creates the VM
- `machine-type` selects the CPU and memory class
- `boot-disk-size` gives enough disk for Docker images and build layers
- `tags` allow firewall rules to target the VM later

### 3. Open HTTP/HTTPS if needed

If you want to access the UI or Nginx gateway from your browser, open ports `80` and `443`.

```bash
gcloud compute firewall-rules create allow-optscale-http \
  --project "$PROJECT_ID" \
  --allow tcp:80,tcp:443 \
  --target-tags "optscale-dev" \
  --description "Allow HTTP/HTTPS to local OptScale stack" \
  --direction INGRESS \
  --priority 1000
```

What this does:

- Creates a firewall rule for web traffic
- Applies only to VMs with the `optscale-dev` tag
- Allows browser access to the gateway service

### 4. Install Docker and Docker Compose

SSH into the VM and install the runtime dependencies.

```bash
gcloud compute ssh "$INSTANCE_NAME" --zone "$ZONE" --project "$PROJECT_ID" --command "$(cat <<'EOF'
set -euo pipefail

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release git openssh-client

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl restart docker
sudo usermod -aG docker "$USER"

docker --version
docker compose version
EOF
)"
```

What this does:

- Installs the packages needed for Docker and Git
- Adds Docker’s official repository
- Installs Docker Engine and the Compose plugin
- Starts Docker and enables it on boot
- Adds the current user to the `docker` group

### 5. Copy the SSH key to the VM

The VM needs SSH access to GitHub so it can clone the private repository.

```bash
gcloud compute scp "$LOCAL_KEY" "$INSTANCE_NAME:~/.ssh/yash_murani_id" \
  --zone "$ZONE" \
  --project "$PROJECT_ID" \
  --tunnel-through-iap
```

What this does:

- Copies the private key file to the VM
- Uses IAP tunneling for a secure transfer
- Places the key in the VM user’s SSH directory

Important note:

- This works, but it is not the most secure long-term pattern
- A better pattern is SSH agent forwarding or a deploy key
- If you use this approach, delete the key from the VM after setup

### 6. Configure SSH on the VM

Set the correct permissions and register the key for GitHub access.

```bash
gcloud compute ssh "$INSTANCE_NAME" --zone "$ZONE" --project "$PROJECT_ID" --command "$(cat <<'EOF'
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
EOF
)"
```

What this does:

- Creates the `.ssh` directory if it does not exist
- Restricts the key file to the owner only
- Tells SSH to use the correct key for GitHub
- Trusts GitHub’s host key automatically the first time
- Tests authentication against GitHub

### 7. Clone the repository

Now that the VM can authenticate with GitHub, clone the repo.

```bash
gcloud compute ssh "$INSTANCE_NAME" --zone "$ZONE" --project "$PROJECT_ID" --command "$(cat <<'EOF'
set -euo pipefail

mkdir -p ~/work
cd ~/work

if [ ! -d optscale-docker ]; then
  git clone git@github.com:yash2801murani/optscale-docker.git
fi

cd optscale-docker
git status
EOF
)"
```

What this does:

- Creates a working directory
- Clones the repository only if it is not already present
- Moves into the repo so the next commands can build and run it

### 8. Prepare the environment file

If the repository contains `.env.example`, copy it to `.env`.

```bash
gcloud compute ssh "$INSTANCE_NAME" --zone "$ZONE" --project "$PROJECT_ID" --command "$(cat <<'EOF'
set -euo pipefail

cd ~/work/optscale-docker

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi
EOF
)"
```

What this does:

- Creates the local environment file used by Docker Compose
- Preserves sane defaults for local development

### 9. Build and start the stack

Use the repository automation to build images and launch the stack.

```bash
gcloud compute ssh "$INSTANCE_NAME" --zone "$ZONE" --project "$PROJECT_ID" --command "$(cat <<'EOF'
set -euo pipefail

cd ~/work/optscale-docker

make build
make up
EOF
)"
```

What this does:

- Builds the Docker images from the local Dockerfiles
- Starts the complete stack in detached mode
- Brings up the databases, backend services, frontend, and gateway

## Verification Steps

### 1. Verify Docker is installed

Run this on the VM:

```bash
docker --version
docker compose version
```

Expected result:

- Both commands print version information
- No permission errors should appear

### 2. Verify GitHub SSH access

Run this on the VM:

```bash
ssh -T git@github.com
```

Expected result:

- GitHub should confirm the authenticated account
- The account should be the one that owns the repo

### 3. Verify the containers are running

Run this inside the repository directory on the VM:

```bash
cd ~/work/optscale-docker
docker compose ps
```

Expected result:

- Core services show `Up`
- The database containers should be healthy
- `nginx` and `ngui` should be running if the full stack is up

### 4. Verify the UI

If port `80` is exposed, open the VM external IP in a browser.

```bash
http://<VM_EXTERNAL_IP>/
```

You can find the external IP with:

```bash
gcloud compute instances describe optscale-local-vm \
  --project project-dd78babb-fa69-4445-a5b \
  --zone us-central1-f \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

### 5. Verify logs

If something is not starting, inspect the service logs.

```bash
cd ~/work/optscale-docker
docker compose logs --tail=200
docker compose logs --tail=200 nginx ngui restapi auth
```

What to look for:

- Database readiness failures
- Missing environment variables
- SSH or Git clone issues
- Backend service startup errors

## Recommended Cleanup

If you copied the private SSH key to the VM, remove it after setup.

```bash
rm -f ~/.ssh/yash_murani_id
```

You should keep the private key only on trusted machines when possible.

## Summary

After completing these steps, you will have:

- A new GCP VM sized for the OptScale stack
- Docker and Docker Compose installed
- GitHub SSH authentication configured
- The repository cloned on the VM
- The application stack running locally in Docker Compose

This is the standard onboarding path for local infrastructure development and smoke testing.
