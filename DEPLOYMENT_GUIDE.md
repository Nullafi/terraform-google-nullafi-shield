# Nullafi Shield — Deployment & End-User Configuration Guide

This guide covers the full deployment lifecycle from infrastructure provisioning on GCP through end-user device configuration (proxy + certificate). It is organized by role so each team can execute their portion independently.

---

## Roles

| Role | Responsibilities |
|---|---|
| **GCP Engineer** | Provision and manage all GCP infrastructure using Terraform |
| **Device Administrator** | Configure end-user machines — install the MITM CA certificate and set the system proxy |
| **Nullafi Admin** | Obtain assets (license key, CA cert/key) from Nullafi; coordinate between roles |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│  End-User Devices  (Windows / macOS)                                    │
│                                                                         │
│   Browser / App                                                         │
│       │  HTTPS request                                                  │
│       ▼                                                                 │
│   System Proxy  ──────────────────────────────────────────────────────► │
│   host: shield.company.com                                              │
│   port: 44509                                                           │
└──────────────────────────────────┬──────────────────────────────────────┘
                                   │  Proxied traffic (CONNECT tunnel)
                                   ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  GCP Project  (same region as Snowflake — e.g. us-east1)                     │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  nullafi-aio-vpc  (10.0.0.0/24)                                         │ │
│  │                                                                         │ │
│  │  Static External IP  (nullafi-aio-ip)                                   │ │
│  │         │                                                               │ │
│  │         ▼                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │ │
│  │  │  nullafi-aio-vm  (Ubuntu 22.04, e2-standard-2, 64 GB SSD)       │   │ │
│  │  │                                                                  │   │ │
│  │  │  docker-compose stack                                            │   │ │
│  │  │                                                                  │   │ │
│  │  │  ┌──────────────┐   ICAP   ┌──────────────┐                     │   │ │
│  │  │  │  squid       │ ───────► │ shield-icap  │  DLP inspection      │   │ │
│  │  │  │  :44509      │          │  :1344       │                     │   │ │
│  │  │  │  MITM proxy  │          └──────┬───────┘                     │   │ │
│  │  │  └──────────────┘                 │ events                      │   │ │
│  │  │                                   ▼                             │   │ │
│  │  │  ┌──────────────┐         ┌──────────────┐                     │   │ │
│  │  │  │ shield-web-ui│         │ shield-alert │  notifications       │   │ │
│  │  │  │  :80 / :443  │         └──────┬───────┘                     │   │ │
│  │  │  │  admin UI +  │                │                              │   │ │
│  │  │  │  Let's Encrypt│               ▼                              │   │ │
│  │  │  └──────┬───────┘        ┌──────────────┐                     │   │ │
│  │  │         │                │  activity    │  Elasticsearch       │   │ │
│  │  │         │                │  (ES 8.7)    │  audit log           │   │ │
│  │  │         │                └──────────────┘                     │   │ │
│  │  │         │                                                      │   │ │
│  │  │         │                ┌──────────────┐                     │   │ │
│  │  │         └───────────────►│   redis      │  session / cache     │   │ │
│  │  │                          └──────────────┘                     │   │ │
│  │  └─────────────────────────────────────────────────────────────────┘   │ │
│  │                                                                         │ │
│  │  Firewall rules                                                         │ │
│  │    nullafi-aio-allow-web  →  TCP 80, 443, 44509  from  0.0.0.0/0       │ │
│  │    nullafi-aio-allow-ssh  →  TCP 22  from  <allowed_ssh_cidrs>         │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  Cloud DNS  (optional)                                                       │
│    A record  shield.company.com  →  static external IP                       │
└──────────────────────────────────────────────────────────────────────────────┘
                        │
                        │  outbound / inspected traffic
                        ▼
              Snowflake (same GCP region)
              Internet destinations
```

**Traffic flow summary:**
1. The browser on an end-user device sends all HTTPS traffic through the system proxy (`shield.company.com:44509`).
2. Squid terminates the TLS connection using the MITM CA certificate (trusted by the device) and re-encrypts toward the destination.
3. Squid sends a copy of each request to `shield-icap` via the ICAP protocol for DLP inspection and policy enforcement.
4. Audit events are stored in Elasticsearch (`activity`). Alerts are dispatched by `shield-alert`.
5. The `shield-web-ui` container serves the admin dashboard and handles Let's Encrypt certificate renewal.

---

## Phase 1 — GCP Engineer: Provision Infrastructure

### 1.1 Prerequisites

| Tool | Minimum Version | Install |
|---|---|---|
| Terraform | ≥ 1.9 | https://developer.hashicorp.com/terraform/install |
| Google Cloud CLI | ≥ 400 | https://cloud.google.com/sdk/docs/install |

### 1.2 GCP Project Setup

- A GCP project with **billing enabled**
- Enable required APIs:

```bash
# Always required
gcloud services enable compute.googleapis.com

# Required only when using Cloud DNS for ACME DNS-01 challenge
gcloud services enable dns.googleapis.com
```

### 1.3 IAM Permissions

The identity running `terraform apply` needs:

| Role | Purpose | When |
|---|---|---|
| `roles/compute.admin` | VPC, subnet, firewall, VM, static IP | Always |
| `roles/iam.securityAdmin` | Create service accounts and bind IAM roles | Always |
| `roles/dns.admin` | Create Cloud DNS A record | Only if using Cloud DNS |

### 1.4 Authentication

**Option A — Application Default Credentials (recommended):**

```bash
gcloud auth application-default login
```

**Option B — Service Account Key File:**

Set the `credentials_file` variable to the JSON key path:

```hcl
credentials_file = "/path/to/key.json"
```

### 1.5 Assets from Nullafi Admin

Before running Terraform, obtain from the **Nullafi Admin**:

| Asset | Format | Notes |
|---|---|---|
| License key | String | Written to `/opt/nullafi/license.key` on the VM |
| MITM CA certificate | PEM file | Used by Squid for TLS interception. Use your existing CA if available. |
| MITM CA private key | PEM file | Must match the certificate above |

### 1.6 DNS & Hostname

Required only when enabling HTTPS (strongly recommended for production):

- Reserve a public hostname (e.g. `shield.company.com`) in your DNS provider
- The DNS A record must point to the static IP **before** HTTPS activates — the startup script waits up to 15 minutes for DNS propagation
- If using **Cloud DNS** in the same GCP project: the managed zone must exist before `terraform apply`

**ACME challenge options:**

| Type | Requirement | Recommended for |
|---|---|---|
| `TLS-ALPN-01` (default) | Port 443 open to internet | Most deployments |
| `HTTP-01` | Port 80 open to internet | Standard web validation |
| `DNS-01` with Cloud DNS | Managed zone in same project | Fully automated, no manual DNS step |
| `DNS-01` with other provider | Provider API credentials | DNS hosted outside GCP |

### 1.7 Terraform Variables

Create a `terraform.tfvars` file (never commit it to source control):

```hcl
# Required
project_id          = "your-gcp-project-id"
nullafi_license_key = "your-nullafi-license-key"
proxy_mitm_cert     = "/path/to/mitm.crt"
proxy_mitm_key      = "/path/to/mitm.key"

# Recommended — HTTPS with a public hostname
host_name           = "shield.company.com"
acme_challenge_type = "TLS-ALPN-01"

# Region — choose the same region as your Snowflake deployment
region = "us-east1"
zone   = "us-east1-b"

# Security — restrict SSH to specific IPs; omit to disable SSH entirely
allowed_ssh_cidrs = ["10.0.0.0/8"]
ssh_public_key    = "ssh-ed25519 AAAA... user@host"

# Change for production
elastic_password = "change-me-in-production"
```

> **Region note:** Deploy in the same GCP region as your Snowflake instance to minimize latency and avoid cross-region egress charges.

### 1.8 Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Terraform outputs the static external IP and the proxy endpoint after apply completes.

### 1.9 GCP Resources Created

| Resource | Type | Default Name |
|---|---|---|
| VPC Network | `google_compute_network` | `nullafi-aio-vpc` |
| Subnet | `google_compute_subnetwork` | `nullafi-aio-subnet` (`10.0.0.0/24`) |
| Firewall — web | `google_compute_firewall` | `nullafi-aio-allow-web` (TCP 80/443/44509) |
| Firewall — SSH (optional) | `google_compute_firewall` | `nullafi-aio-allow-ssh` |
| Static external IP | `google_compute_address` | `nullafi-aio-ip` |
| VM service account | `google_service_account` | `nullafi-aio-vm@{project}.iam.gserviceaccount.com` |
| Compute Engine VM | `google_compute_instance` | `nullafi-aio-vm` |
| Cloud DNS A record | `google_dns_record_set` | `{host_name}.` — conditional |

**VM defaults:**

| Property | Default |
|---|---|
| Machine type | `e2-standard-2` (2 vCPU / 8 GB RAM) |
| OS | Ubuntu 22.04 LTS |
| Boot disk | 64 GB SSD (`pd-ssd`) |
| Secure Boot | Enabled |
| vTPM | Enabled |
| Integrity Monitoring | Enabled |
| VPC Flow Logs | Enabled (5s aggregation, 50% sampling) |

### 1.10 Verify Deployment

After `terraform apply`:

1. Confirm the admin UI is reachable: `https://shield.company.com` (or `http://<static-ip>` if no hostname)
2. Confirm the proxy port is open: `curl -v --proxy http://shield.company.com:44509 https://example.com`
3. Check startup logs via serial console if needed: `gcloud compute instances get-serial-port-output nullafi-aio-vm --zone us-east1-b`

---

## Phase 2 — Device Administrator: End-User Device Configuration

The Device Administrator receives two pieces of information from the Nullafi Admin after Phase 1 completes:

| Item | Example |
|---|---|
| Proxy host | `shield.company.com` |
| Proxy port | `44509` |
| MITM CA certificate file | `mitm.crt` (PEM format) |

These steps can be applied via MDM (Jamf, Intune, etc.) or manually per device.

---

### 2.1 Install the MITM CA Certificate

The MITM CA certificate must be trusted at the OS level so browsers and apps accept HTTPS connections inspected by Squid.

#### macOS

**Via terminal (Keychain):**

```bash
# Install and trust the CA certificate system-wide
sudo security add-trusted-cert \
  -d \
  -r trustRoot \
  -k /Library/Keychains/System.keychain \
  /path/to/mitm.crt
```

**Via GUI:**
1. Double-click `mitm.crt` — Keychain Access opens
2. Add to **System** keychain (not login)
3. Double-click the imported certificate → expand **Trust** → set **"When using this certificate"** to **Always Trust**
4. Close and enter your admin password to save

**Verify:**
```bash
security find-certificate -a -c "Nullafi" /Library/Keychains/System.keychain
```

#### Windows

**Via PowerShell (elevated):**

```powershell
# Import into the machine-wide Trusted Root Certification Authorities store
Import-Certificate `
  -FilePath "C:\path\to\mitm.crt" `
  -CertStoreLocation Cert:\LocalMachine\Root
```

**Via GUI:**
1. Double-click `mitm.crt` → click **Install Certificate**
2. Select **Local Machine** → click **Next**
3. Select **Place all certificates in the following store** → **Browse** → choose **Trusted Root Certification Authorities**
4. Click **Finish** and confirm any security prompts

**Verify (PowerShell):**
```powershell
Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like "*Nullafi*" }
```

> **MDM note:** For enterprise rollouts, push the certificate to the `LocalMachine\Root` store via Intune (Windows) or a Jamf configuration profile (macOS) to avoid touching each device individually.

---

### 2.2 Configure the System Proxy

#### macOS

**Via System Settings (GUI):**
1. Open **System Settings** → **Network**
2. Select the active network interface (Wi-Fi or Ethernet) → **Details**
3. Go to **Proxies** tab
4. Enable **HTTPS Proxy**
5. Set **Server:** `shield.company.com`, **Port:** `44509`
6. Click **OK** and apply

**Via terminal (networksetup):**

```bash
# For Wi-Fi
sudo networksetup -setwebproxy Wi-Fi shield.company.com 44509
sudo networksetup -setsecurewebproxy Wi-Fi shield.company.com 44509
sudo networksetup -setwebproxystate Wi-Fi on
sudo networksetup -setsecurewebproxystate Wi-Fi on

# For Ethernet (replace "Ethernet" with the actual interface name from `networksetup -listallnetworkservices`)
sudo networksetup -setwebproxy Ethernet shield.company.com 44509
sudo networksetup -setsecurewebproxy Ethernet shield.company.com 44509
sudo networksetup -setwebproxystate Ethernet on
sudo networksetup -setsecurewebproxystate Ethernet on
```

**Bypass list (recommended):** Exclude localhost and internal resources from the proxy:

```bash
sudo networksetup -setproxybypassdomains Wi-Fi "localhost" "127.0.0.1" "*.local" "169.254/16"
```

#### Windows

**Via Settings (GUI):**
1. Open **Settings** → **Network & Internet** → **Proxy**
2. Under **Manual proxy setup**, turn on **Use a proxy server**
3. Set **Address:** `shield.company.com`, **Port:** `44509`
4. Add bypass entries: `localhost;127.0.0.1;*.local`
5. Click **Save**

**Via PowerShell (elevated):**

```powershell
$proxyAddress = "shield.company.com:44509"

# Set WinINet proxy (used by IE, Edge, Chrome on Windows)
Set-ItemProperty `
  -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
  -Name ProxyServer -Value $proxyAddress

Set-ItemProperty `
  -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
  -Name ProxyEnable -Value 1

Set-ItemProperty `
  -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
  -Name ProxyOverride -Value "localhost;127.0.0.1;*.local;<local>"
```

**Via Group Policy (enterprise rollout):**
1. Open **Group Policy Management** → create or edit a GPO
2. Navigate to **User Configuration → Windows Settings → Internet Explorer → Connection → Proxy Settings**
3. Enable **Use proxy server**, set address/port, configure exceptions
4. Apply the GPO to the target OU

> **Note:** Firefox manages its own proxy settings. If Firefox is in use, configure it separately under **Settings → Network Settings → Manual proxy configuration**, or enforce through Firefox policies.

---

### 2.3 Verify End-User Configuration

Run from the end-user device after both steps above:

```bash
# macOS / Windows (curl)
curl -v --proxy http://shield.company.com:44509 https://example.com
```

A successful response (HTTP 200) with no certificate errors confirms:
- The MITM CA certificate is trusted
- The proxy is reachable
- TLS interception is working

Check the Nullafi Shield admin dashboard (`https://shield.company.com`) — the device's traffic should appear in the activity log.

---

## Deployment Checklist

### GCP Engineer

- [ ] GCP project created with billing enabled
- [ ] `compute.googleapis.com` enabled
- [ ] `dns.googleapis.com` enabled (if using Cloud DNS)
- [ ] Terraform identity has `roles/compute.admin` and `roles/iam.securityAdmin`
- [ ] Terraform identity has `roles/dns.admin` (if using Cloud DNS)
- [ ] Terraform ≥ 1.9 installed
- [ ] Google Cloud CLI ≥ 400 installed
- [ ] Authentication configured (ADC or service account key)
- [ ] License key, MITM cert, and MITM key received from Nullafi Admin
- [ ] Public hostname reserved and DNS access confirmed (if using HTTPS)
- [ ] Cloud DNS managed zone already exists (if using DNS-01 with Cloud DNS)
- [ ] `terraform.tfvars` created (not committed to source control)
- [ ] `terraform apply` completed successfully
- [ ] Admin UI reachable at `https://shield.company.com`
- [ ] Proxy port 44509 reachable from external test
- [ ] Proxy host and port communicated to Device Administrator

### Device Administrator

- [ ] MITM CA certificate file received from Nullafi Admin
- [ ] Proxy host (`shield.company.com`) and port (`44509`) received from GCP Engineer
- [ ] CA certificate installed in OS trust store on all devices (macOS Keychain / Windows LocalMachine\Root)
- [ ] System proxy configured to `shield.company.com:44509` on all devices
- [ ] Bypass list configured (`localhost`, `127.0.0.1`, `*.local`)
- [ ] Verification curl test passes without certificate errors
- [ ] Device traffic visible in Shield admin activity log
- [ ] Firefox proxy configured separately (if applicable)
