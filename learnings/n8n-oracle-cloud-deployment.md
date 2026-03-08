# n8n Self-Hosted on Oracle Cloud Always Free Tier

Comprehensive deployment guide for running n8n at $0/month on Oracle Cloud Infrastructure (OCI) Always Free Tier. Written for a podcast automation pipeline with 928 RSS feeds and Claude API integration, within a total project budget of EUR 200.

---

## Table of Contents

1. [Oracle Cloud Always Free: What You Get](#1-oracle-cloud-always-free-what-you-get)
2. [Instance Setup](#2-instance-setup)
3. [Server Preparation](#3-server-preparation)
4. [Docker-Based n8n Deployment](#4-docker-based-n8n-deployment)
5. [Domain and SSL Configuration](#5-domain-and-ssl-configuration)
6. [Security Hardening](#6-security-hardening)
7. [Backup Strategy](#7-backup-strategy)
8. [Resource Usage: Will 928 RSS Feeds Fit?](#8-resource-usage-will-928-rss-feeds-fit)
9. [Common Pitfalls and Gotchas](#9-common-pitfalls-and-gotchas)
10. [Maintenance Runbook](#10-maintenance-runbook)

---

## 1. Oracle Cloud Always Free: What You Get

### Always Free Resources (no expiration)

| Resource | Allocation |
|---|---|
| ARM Ampere A1 Compute | Up to 4 OCPUs, 24 GB RAM total (split across up to 4 VMs) |
| AMD Compute | 2 x VM.Standard.E2.1.Micro (1/8 OCPU, 1 GB RAM each) |
| Block Volume Storage | 200 GB total |
| Object Storage | 20 GB |
| Outbound Data Transfer | 10 TB/month |
| Public IP | 1 reserved public IP (free) |
| Load Balancer | 1 flexible (10 Mbps) |

### ARM vs AMD: Which Shape for n8n?

**Use ARM (VM.Standard.A1.Flex) -- this is the clear winner.**

- 4 OCPUs + 24 GB RAM vs 1/8 OCPU + 1 GB RAM on AMD micros
- n8n, PostgreSQL, and Caddy all have ARM64 Docker images
- 24 GB RAM is luxurious for n8n (official recommendation: 2-8 GB)
- The AMD micros are too constrained for anything beyond a basic web server

**Recommended allocation: 1 VM with all 4 OCPUs and 24 GB RAM.** There is no benefit to splitting across multiple VMs for this use case.

---

## 2. Instance Setup

### 2.1 Create Oracle Cloud Account

1. Sign up at https://cloud.oracle.com
2. You need a credit card for verification (you will NOT be charged)
3. Choose your **Home Region** carefully -- you cannot change it later
4. **Recommended regions** (better ARM capacity): US-Ashburn, US-Phoenix, UK-London, Germany-Frankfurt

### 2.2 Upgrade to Pay-As-You-Go (CRITICAL)

Upgrade your account from Free Tier to Pay-As-You-Go **immediately after signup**:

- You will NOT be charged as long as you stay within Always Free limits
- PAYG accounts get priority access to ARM capacity (solving the "Out of Capacity" problem)
- PAYG accounts are NOT subject to idle instance reclamation
- Without PAYG, you will likely spend days fighting "Out of Host Capacity" errors

Navigate to: Billing -> Upgrade and Pay -> follow the prompts.

### 2.3 Create the Compute Instance

Navigate to: Compute -> Instances -> Create Instance

```
Name:           n8n-server
Compartment:    (root)
Image:          Canonical Ubuntu 22.04 (or 24.04)
                -> Change Image -> Ubuntu -> "Always Free Eligible" tag
Shape:          VM.Standard.A1.Flex
                -> Change Shape -> Ampere -> A1.Flex
                -> OCPUs: 4, Memory: 24 GB
Boot Volume:    100 GB (leave default, or increase up to 200 GB)
Networking:     Create new VCN + subnet (use defaults)
SSH Key:        Upload your public key (or generate a new pair)
```

### 2.4 Reserve a Public IP

Navigate to: Networking -> Reserved Public IPs -> Reserve

Then assign it to your instance's VNIC. A reserved IP persists even if you terminate and recreate the instance.

### 2.5 Dealing with "Out of Host Capacity"

If you get this error even after upgrading to PAYG:

1. **Try different availability domains** (if your region has multiple)
2. **Try at off-peak hours** (early morning UTC tends to work)
3. **Use the OCI CLI retry script**: https://github.com/hitrov/oci-arm-host-capacity
4. **Wait 24-72 hours** -- capacity frees up regularly
5. **Last resort**: Try a different region (but this requires a new tenancy)

---

## 3. Server Preparation

### 3.1 SSH In

```bash
ssh -i ~/.ssh/oci_key ubuntu@<YOUR_PUBLIC_IP>
```

### 3.2 System Update

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git wget unzip
```

### 3.3 Install Docker and Docker Compose

```bash
# Install Docker using the official convenience script
curl -fsSL https://get.docker.com | sudo sh

# Add your user to the docker group
sudo usermod -aG docker ubuntu

# Install Docker Compose plugin
sudo apt install -y docker-compose-plugin

# Log out and back in for group changes
exit
# SSH back in

# Verify
docker --version
docker compose version
```

### 3.4 Configure Swap (recommended safety net)

Even with 24 GB RAM, swap prevents OOM kills during traffic spikes:

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 4. Docker-Based n8n Deployment

### 4.1 Directory Structure

```bash
mkdir -p ~/n8n-stack/{n8n_data,postgres_data,caddy_data,caddy_config,local_files,backups}
cd ~/n8n-stack
```

### 4.2 Environment File

Create `~/n8n-stack/.env`:

```env
# Domain Configuration
DOMAIN_NAME=n8n.yourdomain.com
# If using DuckDNS: DOMAIN_NAME=yourname.duckdns.org

# n8n Configuration
N8N_ENCRYPTION_KEY=generate-a-strong-random-key-here
# Generate with: openssl rand -hex 32

# PostgreSQL Configuration
POSTGRES_USER=n8n
POSTGRES_PASSWORD=change-this-to-a-strong-password
POSTGRES_DB=n8n

# Timezone
GENERIC_TIMEZONE=Europe/Berlin

# n8n Execution Pruning (critical for disk management)
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168
EXECUTIONS_DATA_PRUNE_MAX_COUNT=5000
```

**IMPORTANT**: Generate `N8N_ENCRYPTION_KEY` once and NEVER change it. Without this key, all stored credentials become unrecoverable. Back it up securely.

```bash
# Generate the encryption key
openssl rand -hex 32
```

### 4.3 Docker Compose File

Create `~/n8n-stack/docker-compose.yml`:

```yaml
services:
  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"  # HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy_data:/data
      - ./caddy_config:/config
    networks:
      - n8n-net
    depends_on:
      - n8n

  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    networks:
      - n8n-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    environment:
      - N8N_HOST=${DOMAIN_NAME}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${DOMAIN_NAME}/
      - GENERIC_TIMEZONE=${GENERIC_TIMEZONE}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      # Database
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      # Execution pruning
      - EXECUTIONS_DATA_PRUNE=${EXECUTIONS_DATA_PRUNE}
      - EXECUTIONS_DATA_MAX_AGE=${EXECUTIONS_DATA_MAX_AGE}
      - EXECUTIONS_DATA_PRUNE_MAX_COUNT=${EXECUTIONS_DATA_PRUNE_MAX_COUNT}
      # Memory management
      - NODE_OPTIONS=--max-old-space-size=4096
    volumes:
      - ./n8n_data:/home/node/.n8n
      - ./local_files:/files
    networks:
      - n8n-net
    depends_on:
      postgres:
        condition: service_healthy

networks:
  n8n-net:
    driver: bridge
```

### 4.4 Caddyfile

Create `~/n8n-stack/Caddyfile`:

```caddyfile
{$DOMAIN_NAME} {
    reverse_proxy n8n:5678 {
        flush_interval -1
    }
}
```

The `flush_interval -1` is required for n8n's server-sent events (SSE) to work properly (real-time execution updates in the UI).

**Why Caddy over Nginx/Traefik?**
- Automatic HTTPS via Let's Encrypt with zero configuration
- Automatic certificate renewal
- Single config file, no boilerplate
- Lower memory footprint than Traefik

### 4.5 Set Permissions and Launch

```bash
cd ~/n8n-stack

# n8n runs as user 'node' (UID 1000) inside the container
sudo chown -R 1000:1000 n8n_data local_files

# Launch
docker compose up -d

# Check logs
docker compose logs -f

# Verify all 3 containers are running
docker compose ps
```

### 4.6 First Access

1. Open `https://your-domain.com` in a browser
2. Create your owner account (first user becomes admin)
3. Do this IMMEDIATELY -- anyone with the URL can claim the admin account

---

## 5. Domain and SSL Configuration

### Option A: Free Subdomain with DuckDNS ($0)

1. Sign up at https://www.duckdns.org (use GitHub/Google login)
2. Create a subdomain (e.g., `mypodcast.duckdns.org`)
3. Set the IP to your Oracle Cloud instance's public IP
4. Update your `.env`: `DOMAIN_NAME=mypodcast.duckdns.org`

DuckDNS supports Let's Encrypt DNS-01 challenges, but the Caddy HTTP-01 challenge works fine since ports 80/443 are open.

**Keep the IP updated** (if not using a reserved IP):

```bash
# Add to crontab: crontab -e
*/5 * * * * curl -s "https://www.duckdns.org/update?domains=mypodcast&token=YOUR_TOKEN&ip=" > /dev/null
```

### Option B: Cloudflare Tunnel (no open ports, $0)

This is more secure as it requires zero open inbound ports:

1. Register a free domain on Freenom or use one you own
2. Add it to Cloudflare (free plan)
3. Install `cloudflared` on your Oracle instance
4. Create a tunnel: `cloudflared tunnel create n8n`
5. Route your domain to the tunnel

```yaml
# Add to docker-compose.yml
  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token YOUR_TUNNEL_TOKEN
    networks:
      - n8n-net
```

With this approach, you can remove the Caddy service entirely and skip the firewall port-opening steps. Cloudflare handles SSL termination.

### Option C: Cheap Domain (~EUR 1-8/year)

Providers like Porkbun, Namecheap, or Cloudflare Registrar sell `.com` domains for EUR 8-10/year and niche TLDs like `.xyz` or `.site` for EUR 1-3/year.

Create an A record: `n8n.yourdomain.com -> YOUR_ORACLE_IP`

---

## 6. Security Hardening

### 6.1 Oracle Cloud Security List (VCN Firewall)

This is the FIRST layer -- without it, no traffic reaches your instance.

Navigate to: Networking -> Virtual Cloud Networks -> your VCN -> Subnet -> Security List

Add Ingress Rules:

| Source CIDR | Protocol | Dest Port | Description |
|---|---|---|---|
| 0.0.0.0/0 | TCP | 22 | SSH |
| 0.0.0.0/0 | TCP | 80 | HTTP (for Let's Encrypt + redirect) |
| 0.0.0.0/0 | TCP | 443 | HTTPS |

If using Cloudflare Tunnel: only port 22 is needed.

### 6.2 OS-Level Firewall (iptables)

Oracle's Ubuntu images use iptables rules that BLOCK everything except SSH by default. This is the number-one gotcha people hit.

**Do NOT use UFW on Oracle Cloud Ubuntu** -- it conflicts with the existing iptables configuration.

```bash
# Method 1: Edit iptables rules directly (recommended)
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT

# Persist the rules
sudo netfilter-persistent save

# Verify
sudo iptables -L INPUT -n --line-numbers
```

**IMPORTANT**: The `-I INPUT 6` inserts the rule BEFORE the default REJECT rule. If you append with `-A`, the rule is ignored because the REJECT catches traffic first. Check the line number of your REJECT rule with `iptables -L INPUT -n --line-numbers` and insert above it.

### 6.3 SSH Hardening

```bash
sudo nano /etc/ssh/sshd_config
```

Key changes:

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
```

```bash
sudo systemctl restart sshd
```

### 6.4 Fail2ban

```bash
sudo apt install -y fail2ban

sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 6.5 Automatic Security Updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 6.6 n8n Basic Auth (optional extra layer)

If you want HTTP basic auth in front of n8n (Caddy handles this):

```caddyfile
{$DOMAIN_NAME} {
    basicauth / {
        admin $2a$14$HASHED_PASSWORD_HERE
    }
    reverse_proxy n8n:5678 {
        flush_interval -1
    }
}
```

Generate the password hash:

```bash
docker run --rm caddy:2-alpine caddy hash-password --plaintext 'YourSecurePassword'
```

Note: n8n has its own built-in authentication (user accounts). The Caddy basicauth is an optional extra layer that protects even the login page from brute force.

---

## 7. Backup Strategy

### What to Back Up

| Component | Location | Criticality |
|---|---|---|
| PostgreSQL database | `postgres_data/` | CRITICAL -- all workflows, credentials (encrypted), execution history |
| n8n encryption key | `.env` (N8N_ENCRYPTION_KEY) | CRITICAL -- without it, credentials are unrecoverable |
| n8n data directory | `n8n_data/` | Important -- custom nodes, SSH keys |
| Docker Compose files | `docker-compose.yml`, `.env`, `Caddyfile` | Important -- your configuration |
| Caddy data | `caddy_data/` | Low -- certificates auto-regenerate |

### 7.1 Automated Backup Script

Create `~/n8n-stack/backup.sh`:

```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="$HOME/n8n-stack/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/n8n_backup_${TIMESTAMP}"

mkdir -p "${BACKUP_DIR}"

# 1. Dump PostgreSQL
docker compose -f ~/n8n-stack/docker-compose.yml exec -T postgres \
  pg_dump -U n8n -d n8n --clean --if-exists > "${BACKUP_FILE}_db.sql"

# 2. Copy config files
tar czf "${BACKUP_FILE}_config.tar.gz" \
  -C ~/n8n-stack \
  .env docker-compose.yml Caddyfile

# 3. Copy n8n data (encryption keys, custom nodes)
tar czf "${BACKUP_FILE}_n8ndata.tar.gz" \
  -C ~/n8n-stack \
  n8n_data/

# 4. Combine into single archive
tar czf "${BACKUP_FILE}_full.tar.gz" \
  "${BACKUP_FILE}_db.sql" \
  "${BACKUP_FILE}_config.tar.gz" \
  "${BACKUP_FILE}_n8ndata.tar.gz"

# 5. Cleanup individual files
rm -f "${BACKUP_FILE}_db.sql" \
      "${BACKUP_FILE}_config.tar.gz" \
      "${BACKUP_FILE}_n8ndata.tar.gz"

# 6. Remove backups older than 14 days
find "${BACKUP_DIR}" -name "n8n_backup_*_full.tar.gz" -mtime +14 -delete

echo "Backup complete: ${BACKUP_FILE}_full.tar.gz"
echo "Size: $(du -h "${BACKUP_FILE}_full.tar.gz" | cut -f1)"
```

```bash
chmod +x ~/n8n-stack/backup.sh
```

### 7.2 Schedule with Cron

```bash
crontab -e
```

Add:

```
# Daily backup at 3:00 AM
0 3 * * * /home/ubuntu/n8n-stack/backup.sh >> /home/ubuntu/n8n-stack/backups/backup.log 2>&1
```

### 7.3 Off-Server Backup (use OCI Object Storage -- free)

Oracle gives you 20 GB of free Object Storage. Upload backups there:

```bash
# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
oci setup config

# Upload latest backup
LATEST=$(ls -t ~/n8n-stack/backups/n8n_backup_*_full.tar.gz | head -1)
oci os object put \
  --bucket-name n8n-backups \
  --file "${LATEST}" \
  --name "$(basename ${LATEST})"
```

### 7.4 Restore Procedure

```bash
# 1. Stop n8n (keep postgres running)
docker compose stop n8n

# 2. Restore database
docker compose exec -T postgres psql -U n8n -d n8n < backup_db.sql

# 3. Restore n8n data
tar xzf backup_n8ndata.tar.gz -C ~/n8n-stack/

# 4. Restart
docker compose up -d
```

---

## 8. Resource Usage: Will 928 RSS Feeds Fit?

### Short Answer

**Yes, with careful architecture.** 4 OCPUs and 24 GB RAM is more than enough for n8n itself. The bottleneck is execution design, not raw resources.

### n8n Resource Profile

| Component | Expected Usage |
|---|---|
| n8n process | 200-500 MB RAM baseline, spikes to 1-2 GB during heavy execution |
| PostgreSQL | 200-500 MB RAM (with shared_buffers tuned) |
| Caddy | 20-50 MB RAM |
| OS overhead | ~500 MB RAM |
| **Total baseline** | **~1.5 GB of 24 GB** |

You have roughly 22 GB of RAM headroom. The constraint is not memory but **execution design**.

### RSS Feed Strategy

**DO NOT create 928 individual RSS trigger workflows.** This will:
- Create 928 polling intervals competing for resources
- Generate enormous execution history (millions of rows/month)
- Overwhelm the n8n scheduler

**Instead, batch the RSS feeds:**

1. **Group feeds into batches of 50-100** per workflow
2. Use the **HTTP Request node** (not RSS Trigger) to fetch feeds in a loop
3. **Stagger execution times** across workflows (e.g., batch 1 at :00, batch 2 at :05, etc.)
4. **Poll frequency**: Every 30-60 minutes is plenty for podcast RSS feeds (they update at most a few times per day)

```
928 feeds / 50 per workflow = ~19 workflows
19 workflows * 2 executions/hour = 38 executions/hour
Each execution: ~5-10 seconds processing time
Total CPU time: ~6 minutes/hour = 10% CPU utilization
```

### Claude API Integration

Claude API calls are external HTTP requests -- they consume minimal local resources. The cost is on the API side (your EUR 200 budget), not on the server.

Estimated Claude API costs for podcast processing depend heavily on:
- Prompt size (transcript length)
- Model choice (Haiku vs Sonnet vs Opus)
- Number of episodes processed per day

### Execution Data Management

With 928 feeds polling regularly, execution pruning is **non-negotiable**:

```env
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168        # 7 days
EXECUTIONS_DATA_PRUNE_MAX_COUNT=5000
```

Without pruning, your PostgreSQL database will grow by several GB per month and eventually fill the 100-200 GB disk.

### PostgreSQL Maintenance

Add a weekly VACUUM to your crontab:

```bash
# Weekly vacuum on Sundays at 4 AM
0 4 * * 0 docker compose -f ~/n8n-stack/docker-compose.yml exec -T postgres vacuumdb -U n8n -d n8n --analyze >> /home/ubuntu/n8n-stack/backups/vacuum.log 2>&1
```

---

## 9. Common Pitfalls and Gotchas

### Oracle Cloud Specific

1. **"Out of Host Capacity" for ARM instances**
   - FIX: Upgrade to PAYG immediately. Use the retry script if needed.

2. **Ports 80/443 not reachable even after Security List update**
   - ROOT CAUSE: Oracle Ubuntu images have iptables rules blocking all non-SSH traffic.
   - FIX: See Section 6.2. You must open ports at BOTH the VCN Security List AND the OS iptables level.

3. **Idle Instance Reclamation**
   - Oracle reclaims Always Free instances with <20% CPU (95th percentile) over 7 days.
   - PAYG accounts are EXEMPT from reclamation.
   - If you stay on Free Tier only: n8n polling 928 feeds will likely keep CPU above 20%, but this is unreliable.
   - FIX: Upgrade to PAYG (you still pay $0 within Always Free limits).

4. **Boot Volume Minimum is 47 GB**
   - With 200 GB total block storage, you can have one 200 GB boot volume, or split it (e.g., 100 GB boot + 100 GB data volume).

5. **Instance Creation Region Lock**
   - Your Home Region is permanent. Choose one with good ARM capacity.

6. **IPv6 not available on Always Free**
   - Only IPv4 public IPs are available on the free tier.

### n8n Specific

7. **First user registration is open**
   - The first person to visit your n8n URL becomes the owner. Set up your account immediately after deployment.

8. **WEBHOOK_URL must include trailing slash**
   - Wrong: `WEBHOOK_URL=https://n8n.example.com`
   - Right: `WEBHOOK_URL=https://n8n.example.com/`

9. **N8N_ENCRYPTION_KEY is forever**
   - If you lose this key, ALL stored credentials are permanently lost.
   - Back it up in a password manager, not just on the server.

10. **Execution data grows fast**
    - With 928 RSS feeds, expect millions of execution records per month if unpruned.
    - Set `EXECUTIONS_DATA_PRUNE=true` from day one.
    - Even with pruning, run PostgreSQL VACUUM weekly.

11. **Docker image updates can break things**
    - Pin to a specific version instead of `latest` for production stability.
    - Example: `n8nio/n8n:1.76.1` instead of `n8nio/n8n:latest`
    - Test updates on a separate workflow before upgrading.

12. **n8n runs as UID 1000 inside Docker**
    - Volume permissions must match: `sudo chown -R 1000:1000 n8n_data local_files`

13. **Memory leaks on long-running instances**
    - Set `NODE_OPTIONS=--max-old-space-size=4096` to cap Node.js heap.
    - Schedule a weekly container restart if you notice memory creep:
    ```bash
    # Weekly restart Sunday 5 AM
    0 5 * * 0 docker compose -f ~/n8n-stack/docker-compose.yml restart n8n
    ```

---

## 10. Maintenance Runbook

### Update n8n

```bash
cd ~/n8n-stack

# Backup first
./backup.sh

# Pull new image
docker compose pull n8n

# Recreate container
docker compose up -d n8n

# Check logs for migration errors
docker compose logs -f n8n
```

### Monitor Disk Usage

```bash
# Check overall disk
df -h /

# Check Docker volumes
du -sh ~/n8n-stack/postgres_data/
du -sh ~/n8n-stack/n8n_data/

# Check PostgreSQL database size
docker compose exec postgres psql -U n8n -d n8n -c "SELECT pg_size_pretty(pg_database_size('n8n'));"
```

### View Running Executions

```bash
docker compose exec postgres psql -U n8n -d n8n -c "SELECT COUNT(*), status FROM execution_entity GROUP BY status;"
```

### Emergency: n8n Won't Start

```bash
# Check logs
docker compose logs --tail=100 n8n

# Common fixes:
# 1. Permission issue
sudo chown -R 1000:1000 ~/n8n-stack/n8n_data

# 2. Database connection issue
docker compose restart postgres
sleep 5
docker compose restart n8n

# 3. Out of memory
docker compose down
sudo swapon --show  # verify swap is active
docker compose up -d
```

---

## Cost Summary

| Item | Cost |
|---|---|
| Oracle Cloud compute, storage, networking | EUR 0 (Always Free) |
| Domain (DuckDNS) | EUR 0 |
| SSL certificate (Let's Encrypt via Caddy) | EUR 0 |
| Backups (OCI Object Storage, 20 GB free) | EUR 0 |
| **Total hosting cost** | **EUR 0/month** |

The entire EUR 200 budget remains available for Claude API credits and any other paid services in the pipeline.

---

## Sources

- [Oracle Cloud Always Free Resources Documentation](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [Oracle Cloud Free Tier FAQ](https://www.oracle.com/cloud/free/faq/)
- [n8n Official Docker Compose Setup](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/)
- [n8n Execution Data Pruning](https://docs.n8n.io/hosting/scaling/execution-data/)
- [n8n Memory Errors Documentation](https://docs.n8n.io/hosting/scaling/memory-errors/)
- [n8n-docker-caddy-postgres by Joffcom](https://github.com/Joffcom/n8n-docker-caddy-postgres)
- [n8n-hosting Official Repository (withPostgres)](https://github.com/n8n-io/n8n-hosting/blob/main/docker-compose/withPostgres/README.md)
- [OCI ARM Host Capacity Retry Script](https://github.com/hitrov/oci-arm-host-capacity)
- [n8n Setup on Oracle Cloud by gopalshivapuja](https://github.com/gopalshivapuja/n8n-setup-on-oracle-cloud)
- [Self-Host n8n for Free on Oracle Cloud (AutomateStack)](https://automatestack.dev/self-host-n8n-for-free-for-life-on-oracle-cloud)
- [Oracle Cloud Ubuntu Firewall Configuration](https://blogs.oracle.com/developers/enabling-network-traffic-to-ubuntu-images-in-oracle-cloud-infrastructure)
- [n8n Backup Strategy (MassiveGRID)](https://massivegrid.com/blog/n8n-backup-disaster-recovery/)
- [Dale Nguyen's Oracle Cloud n8n Guide (ITNEXT)](https://itnext.io/mastering-automation-a-step-by-step-guide-to-deploying-n8n-on-oracle-cloud-free-tier-3e9c84cdba9e)
- [DuckDNS](https://www.duckdns.org)
- [n8n Community: Monitoring 50+ RSS Feeds](https://community.n8n.io/t/what-would-be-the-best-practice-method-to-monitor-50-rss-feeds/12629)
