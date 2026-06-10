# Nullafi Shield — All-in-One Deployment Guide (GCP)

Deploys the entire Nullafi Shield stack on a **single Compute Engine VM** using docker-compose. Best for evaluation, small deployments, and environments where simplicity matters more than redundancy. This is the GCP analog of the AWS/Azure all-in-one scenarios.

**What you get:**
- One Compute Engine VM (Ubuntu 22.04) with a static external IP
- Shield Web UI, ICAP, Alert, Squid proxy, Activity (Elasticsearch), Redis — all running via docker-compose
- Optional HTTPS via Let's Encrypt (three validation methods supported)
- Auto-restart with docker-compose `restart: unless-stopped`

**TLS model:** all TLS terminates *inside* the `shield-web-ui` container via Let's Encrypt. There is no load balancer and no Google-managed certificate — the external IP is a plain L4 passthrough.

---

## Step 1 — Prerequisites

Install these on your local machine:

| Tool | Version | Install |
|---|---|---|
| Terraform | ≥ 1.9 | <https://developer.hashicorp.com/terraform/install> |
| Google Cloud CLI | ≥ 400 | <https://cloud.google.com/sdk/docs/install> |

You also need:

- **A GCP project** with the **Compute Engine API** enabled (`gcloud services enable compute.googleapis.com`). For DNS-01, also enable the **Cloud DNS API** (`dns.googleapis.com`).
- **Credentials** — either Application Default Credentials (`gcloud auth application-default login`) or a service-account key JSON referenced by `credentials_file`. The identity needs permissions to create Compute, networking, IAM service-account, and (optional) Cloud DNS resources.
- **A Nullafi license key** (provided by Nullafi)
- **A Squid MITM certificate + private key** (`nullafi_YYYY.crt` / `nullafi_YYYY.key`, provided by Nullafi)
- **A public DNS hostname** you control (e.g. `shield.yourcompany.com`) if you want HTTPS

---

## Step 2 — Enter the folder and add your certs

```bash
cd terraform-gcp-deployment/deployments/all-in-one
cp /path/to/nullafi_2026.crt ./nullafi_2026.crt
cp /path/to/nullafi_2026.key ./nullafi_2026.key
```

---

## Step 3 — Configure `terraform.tfvars`

Copy the example and edit it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Minimum config (HTTP only, no hostname):

```hcl
project_id = "mdc-defender3"
region     = "us-east1"
zone       = "us-east1-b"

nullafi_license_key = "key..."   # provided by Nullafi

proxy_mitm_cert = "./nullafi.crt"
proxy_mitm_key  = "./nullafi.key"
```

With this config, Shield will be reachable at `http://<external-ip>/login` after deployment.

### To enable HTTPS (recommended)

Add a public DNS hostname and pick an ACME challenge type:

```hcl
host_name           = "shield.yourcompany.com"
acme_challenge_type = "TLS-ALPN-01"   # default; see comparison below
```

**Choosing the ACME challenge type:**

| Type | When to use | Requirements |
|---|---|---|
| `HTTP-01` | Default web validation | Port 80 open to internet (it is, by default) |
| `TLS-ALPN-01` | Recommended for most users | Port 443 open to internet (it is, by default) |
| `DNS-01` | Issue certs without exposing ports 80/443, or wildcard certs | Supported DNS provider + credentials (see below) |

**DNS-01 with Cloud DNS** (fully automated):

```hcl
host_name           = "shield.yourcompany.com"
acme_challenge_type = "DNS-01"
acme_dns01_provider = "gcloud"
dns_managed_zone    = "yourcompany-com"   # Cloud DNS managed-zone resource name
```

When `dns_managed_zone` is set, Terraform will:
- Auto-create the `shield.yourcompany.com` A record pointing at the static IP
- Grant the VM's service account `roles/dns.admin` so the ACME client can write `_acme-challenge` TXT records
- Inject `GCE_PROJECT` into the container so the `gcloud` DNS-01 provider authenticates via the VM's service account

**DNS-01 with another provider** (e.g. Cloudflare):

```hcl
host_name           = "shield.yourcompany.com"
acme_challenge_type = "DNS-01"
acme_dns01_provider = "cloudflare"
acme_dns01_env = {
  CF_API_TOKEN = "your-cloudflare-api-token"
}
```

You must create the DNS A record yourself before HTTPS will activate (see Step 6).

### Optional: enable SSH access

```hcl
ssh_public_key    = "ssh-ed25519 AAAA..."   # your public key
allowed_ssh_cidrs = ["203.0.113.42/32"]     # your office/home IP
```

Even without this, you can always reach the VM with `gcloud compute ssh` (via IAP / OS Login) or the serial console.

---

## Step 4 — Deploy

```bash
terraform init      # add -backend-config="bucket=<your-gcs-bucket>" for remote state
terraform plan      # review what will be created
terraform apply     # type 'yes' to confirm
```

> **Remote state:** `backend.tf` configures a GCS backend with prefix `all-in-one`. Provide the bucket at init time: `terraform init -backend-config="bucket=nullafi-tfstate-<project>"`. To use local state instead, delete `backend.tf`.

Apply takes ~2 minutes to create infra; the VM then needs another ~5–15 min to install Docker and pull images. When it finishes, Terraform prints:

```
Outputs:
  public_ip            = "34.x.x.x"
  shield_web_ui_url    = "https://shield.yourcompany.com/login"
  dns_instructions     = "Create a DNS A record: shield.yourcompany.com → 34.x.x.x"
  squid_proxy_endpoint = "34.x.x.x:44509"
  ssh_command          = "gcloud compute ssh nullafi-aio-vm --zone us-east1-b"
```

---

## Step 5 — Point DNS at the static IP

**Skip this step if you used `dns_managed_zone`** — the A record is already created.

In your DNS provider's control panel, create an **A record**:

| Name | Type | Value |
|---|---|---|
| `shield.yourcompany.com` | A | `34.x.x.x` (the `public_ip` output) |

Verify with:

```bash
dig +short shield.yourcompany.com
# should return 34.x.x.x
```

---

## Step 6 — Wait for containers to start

On first boot, the VM:
1. Installs Docker + the compose plugin
2. Waits for DNS to resolve to the static IP (up to `dns_wait_timeout` seconds, default 15 min)
3. Starts the Nullafi stack
4. Attempts Let's Encrypt certificate issuance (if `host_name` is set)

To watch progress:

```bash
gcloud compute ssh nullafi-aio-vm --zone us-east1-b
sudo journalctl -u google-startup-scripts -f      # startup-script output
sudo docker logs -f shield-web-ui                  # Shield logs
```

Look for lines like `obtained SSL certificate` or `certificate obtained successfully`.

---

## Step 7 — Log in to the Shield Web UI

Open the `shield_web_ui_url` from Step 4's output:

```
https://shield.yourcompany.com/login
```

Use the credentials provided by Nullafi for first login. A certificate warning means Let's Encrypt hasn't issued yet — wait a few minutes and reload.

---

## Step 8 — Configure the Squid proxy (optional)

The Squid proxy is reachable at `<external-ip>:44509`. Configure it as your HTTP/HTTPS proxy. Install the MITM certificate (`nullafi_2026.crt`) as a trusted root CA on any client routing traffic through Squid.

---

## Updating the deployment

The VM's `metadata["startup-script"]` and boot image are in `ignore_changes`, so editing them won't force a rebuild. To roll new container images, SSH in and run:

```bash
cd /opt/nullafi && sudo docker compose pull && sudo docker compose up -d
```

Infra-level changes (firewall, machine type, etc.) apply normally with `terraform apply`. Changing `machine_type` restarts the VM; the static IP and data disks are preserved.

---

## Tearing down

```bash
terraform destroy
```

Removes the VM, static IP, VPC, firewall rules, service account, and any Cloud DNS record created by Terraform. DNS records you created manually (Step 5) must be deleted manually.

---

## Troubleshooting

### Shield Web UI won't load
1. Check DNS: `dig +short shield.yourcompany.com` should return the static IP
2. Check containers: `gcloud compute ssh ... -- sudo docker ps` — all should be `Up`
3. Check logs: `sudo docker logs shield-web-ui | tail -50`

### Let's Encrypt certificate never issues
- **HTTP-01 / TLS-ALPN-01**: DNS must point to the static IP before the container boots. If DNS was slow, restart: `sudo docker compose -f /opt/nullafi/docker-compose.yml restart`.
- **DNS-01 (Cloud DNS)**: confirm the Cloud DNS API is enabled and the VM SA has `roles/dns.admin` (Terraform grants it when `dns_managed_zone` is set).
- **DNS-01 (other)**: verify the credentials in `acme_dns01_env`.
- **Rate limits**: Let's Encrypt allows 5 certs per domain per week.

### Change the VM size
Update `machine_type` and `terraform apply` (restarts the VM; IP preserved).

---

## Variable reference

| Variable | Required | Default | Description |
|---|---|---|---|
| `project_id` | yes | — | GCP project ID |
| `region` | no | `us-east1` | GCP region |
| `zone` | no | `us-east1-b` | Zone for the VM (within `region`) |
| `credentials_file` | no | `null` | SA key JSON path; null = Application Default Credentials |
| `nullafi_license_key` | yes | — | License key provided by Nullafi |
| `proxy_mitm_cert` | yes | — | Path to Squid MITM certificate |
| `proxy_mitm_key` | yes | — | Path to Squid MITM private key |
| `host_name` | no | `null` | Public hostname (enables HTTPS when set) |
| `acme_challenge_type` | no | `TLS-ALPN-01` | `HTTP-01`, `TLS-ALPN-01`, or `DNS-01` |
| `acme_dns01_provider` | no | `null` | DNS provider name (e.g. `gcloud`, `cloudflare`) |
| `acme_dns01_env` | no | `{}` | Provider-specific credential env vars (sensitive) |
| `dns_managed_zone` | no | `null` | Cloud DNS zone name — auto-creates A record + grants dns.admin |
| `dns_wait_timeout` | no | `900` | Seconds to wait for DNS before starting containers |
| `machine_type` | no | `e2-standard-2` | Compute Engine machine type |
| `os_disk_size_gb` | no | `64` | Boot disk size (GB) |
| `ssh_public_key` | no | `null` | SSH public key for `ssh_user` (null disables key SSH) |
| `ssh_user` | no | `nullafi` | SSH username seeded into metadata |
| `allowed_ssh_cidrs` | no | `[]` | CIDRs allowed SSH access |
| `name_prefix` | no | `nullafi-aio` | Resource name prefix |
| `subnet_cidr` | no | `10.0.0.0/24` | Subnet CIDR |
| `proxy_port` | no | `44509` | External port for Squid |
| `labels` | no | `{}` | Labels applied to resources that support them |
