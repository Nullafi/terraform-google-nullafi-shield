# terraform-google-nullafi-shield

[![Static analysis](https://github.com/Joinesty/terraform-gcp-deployment/actions/workflows/static-analysis.yml/badge.svg)](https://github.com/Joinesty/terraform-gcp-deployment/actions/workflows/static-analysis.yml)

Deploys the full [Nullafi Shield](https://nullafi.com) stack on GCP — a single Compute Engine VM running the Shield web UI, ICAP server, alert processor, Squid MITM proxy, Elasticsearch, and Redis via docker-compose. Static external IP, optional Let's Encrypt HTTPS, and Shielded VM security out of the box.

## Usage

```hcl
provider "google" {
  project = "my-gcp-project"
  region  = "us-east1"
  zone    = "us-east1-b"
}

module "nullafi_shield" {
  source  = "nullafi/nullafi-shield/google"
  version = "~> 1.0"

  project_id          = "my-gcp-project"
  nullafi_license_key = "key provided by Nullafi"
  proxy_mitm_cert     = "./mitm.crt"   # your CA cert, or one provided by Nullafi
  proxy_mitm_key      = "./mitm.key"

  # Optional: enable HTTPS via Let's Encrypt
  host_name           = "shield.yourcompany.com"
  acme_challenge_type = "TLS-ALPN-01"
  name_prefix = "all-in-one" # optional
}
```

After `terraform apply`:

```
Outputs:
  public_ip            = "34.x.x.x"
  shield_web_ui_url    = "https://shield.yourcompany.com/login"
  squid_proxy_endpoint = "34.x.x.x:44509"
  ssh_command          = "gcloud compute ssh nullafi-aio-vm --zone us-east1-b"
```

## Deployments

- [all-in-one](./deployments/all-in-one/) — Single VM, full stack via docker-compose. Best for evaluation and small deployments.

## Requirements

See [REQUIREMENTS.md](https://github.com/Nullafi/terraform-google-nullafi-shield/edit/main/REQUIREMENTS.md) for the full prerequisites: GCP APIs to enable, IAM roles needed, and assets provided by Nullafi (license key, MITM certificate).

## Resources created

| Resource | Type |
|---|---|
| VPC + subnet | `google_compute_network`, `google_compute_subnetwork` |
| Firewall rules (web + optional SSH) | `google_compute_firewall` |
| Static external IP | `google_compute_address` |
| VM service account | `google_service_account` |
| Compute Engine VM (Ubuntu 22.04, Shielded) | `google_compute_instance` |
| Cloud DNS A record (conditional) | `google_dns_record_set` |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_id` | GCP project ID | `string` | — | yes |
| `nullafi_license_key` | Nullafi license key | `string` | `null` | yes |
| `proxy_mitm_cert` | Path to the MITM CA certificate (PEM). Use your existing CA cert if available; Nullafi can provide one if not. | `string` | `null` | yes |
| `proxy_mitm_key` | Path to the MITM CA private key (PEM). Must match `proxy_mitm_cert`. | `string` | `null` | yes |
| `region` | GCP region | `string` | `us-east1` | no |
| `zone` | GCP zone | `string` | `us-east1-b` | no |
| `machine_type` | Compute Engine machine type | `string` | `e2-standard-2` | no |
| `host_name` | Public hostname — enables HTTPS when set | `string` | `null` | no |
| `acme_challenge_type` | `HTTP-01`, `TLS-ALPN-01`, or `DNS-01` | `string` | `TLS-ALPN-01` | no |
| `acme_dns01_provider` | DNS-01 provider (e.g. `gcloud`, `cloudflare`) | `string` | `null` | no |
| `acme_dns01_env` | Credentials env vars for DNS-01 provider | `map(string)` | `{}` | no |
| `dns_managed_zone` | Cloud DNS zone name — auto-creates A record + grants `dns.admin` | `string` | `null` | no |
| `allowed_ssh_cidrs` | CIDRs for SSH access — empty disables SSH | `list(string)` | `[]` | no |
| `ssh_public_key` | SSH public key to install on the VM | `string` | `null` | no |
| `elastic_password` | Elasticsearch password | `string` | `elastic` | no |
| `proxy_port` | External port for Squid proxy | `number` | `44509` | no |
| `labels` | Labels applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `public_ip` | Static external IP |
| `shield_web_ui_url` | Shield Web UI URL |
| `squid_proxy_endpoint` | Squid proxy endpoint (`ip:port`) |
| `dns_instructions` | DNS A record instructions (or confirmation if auto-created) |
| `ssh_command` | SSH command to reach the VM |
| `instance_name` | Compute Engine instance name |
| `vpc_name` | VPC network name |
| `service_account_email` | VM service account email |

## Releasing

Versions and [CHANGELOG.md](CHANGELOG.md) are updated automatically when commits land on `main` via [semantic-release](https://github.com/semantic-release/semantic-release) and [Conventional Commits](https://www.conventionalcommits.org/).

| Prefix | Version bump |
|---|---|
| `feat:` | Minor |
| `fix:` | Patch |
| `feat!:` / `BREAKING CHANGE:` | Major |
| `docs:`, `chore:`, `refactor:` | No bump |
