# Nullafi Shield — GCP Deployment Requirements

Everything a customer needs to have in place before running `terraform apply` to deploy the Nullafi Shield all-in-one stack on GCP.

---

## 1. Local Tooling

| Tool | Minimum Version | Install |
|---|---|---|
| Terraform | ≥ 1.9 | <https://developer.hashicorp.com/terraform/install> |
| Google Cloud CLI | ≥ 400 | <https://cloud.google.com/sdk/docs/install> |

---

## 2. GCP Project

- A GCP project with **billing enabled**
- The **Compute Engine API** must be enabled:

```bash
gcloud services enable compute.googleapis.com
```

- If using **DNS-01 ACME challenge with Cloud DNS**, also enable:

```bash
gcloud services enable dns.googleapis.com
```

---

## 3. IAM Permissions

The user or service account running `terraform apply` needs the following roles on the GCP project:

| Role | Purpose | Required |
|---|---|---|
| `roles/compute.admin` | Create VPC, subnet, firewall rules, VM, and static IP | Always |
| `roles/iam.securityAdmin` | Create service accounts and bind IAM roles | Always |
| `roles/dns.admin` | Create Cloud DNS A record and grant DNS access to VM | Only if using Cloud DNS |

---

## 4. Authentication

**Option A — Application Default Credentials (recommended):**

```bash
gcloud auth application-default login
```

**Option B — Service Account Key File:**

Set the `credentials_file` variable to the path of the JSON key file:

```hcl
credentials_file = "/path/to/key.json"
```

---

## 5. Assets Provided by Nullafi

The following must be obtained from Nullafi before deployment:

| Asset | Description |
|---|---|
| **License key** | Nullafi Shield license key string |
| **MITM certificate** | MITM CA certificate (PEM format). Use your existing CA cert if available; Nullafi can provide one if not. |
| **MITM private key** | MITM CA private key (PEM format). Must match the certificate above. |

---

## 6. DNS & Hostname (HTTPS Only)

Required only if enabling HTTPS via Let's Encrypt.

- A public hostname the customer controls (e.g. `shield.yourcompany.com`)
- The DNS record must point to the static IP **before** HTTPS activates
  - The startup script waits up to 15 minutes for DNS to resolve
- If using **DNS-01 with Cloud DNS**: the managed zone must **already exist** in the GCP project before `terraform apply`

**ACME challenge type comparison:**

| Type | Requirements | Use case |
|---|---|---|
| `TLS-ALPN-01` (default) | Port 443 open to internet | Recommended for most deployments |
| `HTTP-01` | Port 80 open to internet | Standard web validation |
| `DNS-01` with Cloud DNS | Managed zone in the same GCP project | Fully automated; no need to create DNS record manually |
| `DNS-01` with other provider | Provider API credentials (e.g. `CF_API_TOKEN` for Cloudflare) | When DNS is hosted outside GCP |

---

## 7. GCP Resources Created by Terraform

Terraform creates and manages the following resources in the customer's project:

| Resource | Type | Default Name |
|---|---|---|
| VPC Network | `google_compute_network` | `nullafi-aio-vpc` |
| Subnet | `google_compute_subnetwork` | `nullafi-aio-subnet` (`10.0.0.0/24`) |
| Firewall — Web traffic | `google_compute_firewall` | `nullafi-aio-allow-web` |
| Firewall — SSH access | `google_compute_firewall` | `nullafi-aio-allow-ssh` |
| Static external IP | `google_compute_address` | `nullafi-aio-ip` |
| VM service account | `google_service_account` | `nullafi-aio-vm@{project}.iam.gserviceaccount.com` |
| Compute Engine VM | `google_compute_instance` | `nullafi-aio-vm` |
| Cloud DNS A record | `google_dns_record_set` | `{host_name}.` — conditional |

> The SSH firewall rule is only created if `allowed_ssh_cidrs` is set. The DNS A record is only created if both `dns_managed_zone` and `host_name` are set.

### Compute Engine VM Defaults

| Property | Default |
|---|---|
| Machine type | `e2-standard-2` |
| OS | Ubuntu 22.04 LTS |
| Boot disk | 64 GB SSD (`pd-ssd`) |
| Region / Zone | `us-east1` / `us-east1-b` |
| Secure Boot | Enabled |
| vTPM | Enabled |
| Integrity Monitoring | Enabled |
| VPC Flow Logs | Enabled (5s aggregation, 50% sampling) |

### Firewall Rules

| Rule | Protocol | Ports | Source |
|---|---|---|---|
| Web traffic | TCP | 80, 443, 44509 | `0.0.0.0/0` |
| SSH (optional) | TCP | 22 | `allowed_ssh_cidrs` only |

---

## 8. Service Account Created by Terraform

Terraform creates one service account used by the Compute Engine VM:

| Attribute | Value |
|---|---|
| ID | `{name_prefix}-vm` (default: `nullafi-aio-vm`) |
| Display name | Nullafi Shield all-in-one VM |
| OAuth scope | `cloud-platform` |
| IAM role granted | `roles/dns.admin` — only if `dns_managed_zone` and `host_name` are both set |

The `roles/dns.admin` role is granted at the **project level** and allows the VM to automatically create and rotate `_acme-challenge` TXT records during Let's Encrypt DNS-01 validation.

---

## 9. Required Variables

These must always be provided by the customer:

| Variable | Description |
|---|---|
| `project_id` | GCP project ID |
| `nullafi_license_key` | Nullafi Shield license key (sensitive) |
| `proxy_mitm_cert` | Path to the Squid MITM certificate file |
| `proxy_mitm_key` | Path to the Squid MITM private key file (sensitive) |

---

## 10. Key Optional Variables

| Variable | Default | Description |
|---|---|---|
| `region` | `us-east1` | GCP region |
| `zone` | `us-east1-b` | GCP zone (must be within `region`) |
| `machine_type` | `e2-standard-2` | Compute Engine machine type |
| `host_name` | `null` | Public hostname — enables HTTPS when set |
| `acme_challenge_type` | `TLS-ALPN-01` | `HTTP-01`, `TLS-ALPN-01`, or `DNS-01` |
| `acme_dns01_provider` | `null` | DNS-01 provider name (e.g. `gcloud`, `cloudflare`) |
| `acme_dns01_env` | `{}` | Provider credentials for DNS-01 (e.g. `CF_API_TOKEN`) |
| `dns_managed_zone` | `null` | Cloud DNS zone name — auto-creates A record and grants `dns.admin` |
| `allowed_ssh_cidrs` | `[]` | Source CIDRs for SSH access — empty disables SSH |
| `ssh_public_key` | `null` | SSH public key to install on the VM |
| `elastic_password` | `elastic` | Elasticsearch password — change for production |
| `proxy_port` | `44509` | External port for the Squid proxy |

---

## 11. Pre-Deployment Checklist

- [ ] GCP project created with billing enabled
- [ ] `compute.googleapis.com` enabled (+ `dns.googleapis.com` if using Cloud DNS)
- [ ] Terraform identity has `roles/compute.admin` and `roles/iam.securityAdmin`
- [ ] Terraform identity has `roles/dns.admin` if managing Cloud DNS records
- [ ] Terraform ≥ 1.9 installed locally
- [ ] Google Cloud CLI ≥ 400 installed locally
- [ ] Authentication configured (ADC or service account key)
- [ ] Nullafi license key available
- [ ] MITM certificate and private key files available (PEM format)
- [ ] Public hostname reserved and DNS access available (if using HTTPS)
- [ ] Cloud DNS managed zone already exists in the project (if using DNS-01 with Cloud DNS)
- [ ] DNS-01 provider credentials available (if using DNS-01 with a non-GCP provider)
- [ ] Source IPs identified for SSH access (if SSH access is needed)
