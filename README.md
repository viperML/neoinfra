# viperML/neoinfra

Configuration files for my servers

## Roles

### `sumati`
- Multi-purpose VPS
- Nomad server, with just itself as client
- Hosting https://ayats.org
- Hosted on Hetzner Cloud

### `lagos`
- SSH certificate authority using Step-CA
- Signs trusted certificates to connect to `sumati` without SSH keys or username+password
- Hosted on Google Cloud Platform

### `kalypso`
- Hashicorp Vault server
- Provisions secrets to `sumati`'s Nomad runner
- Hosted on Oracle Cloud Infrastructure
