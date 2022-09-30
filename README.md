# viperML/neoinfra

Configuration files for my servers

## Roles

### `sumati`
- Multi-purpose VPS
- Nomad server, with just itself as client
- Hosting https://ayats.org
- Hetzner Cloud

### `skadi`
- Certificate authority using Step-CA
- Signs SSH certificates to connect to other nodes with 2FA (no passwords or ssh keys)
- Oracle Cloud

### `kalypso`
- Hashicorp Vault server
- Provisions secrets to other nodes
- Oracle Cloud

### `chandra`
- Multi-purpose VPS
- Oracle Cloud
