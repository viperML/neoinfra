# viperML/neoinfra

Configuration files for my servers

## Roles

### `chandra`
- Multi-purpose VPS
- Nomad container runtime
- @ Oracle Cloud

### `skadi`
- Certificate authority using Step-CA
- Signs SSH certificates to connect to other nodes with 2FA (no passwords or ssh keys)
- @ Oracle Cloud

### `kalypso`
- Hashicorp Vault server
- Provisions secrets to other nodes
- @ Oracle Cloud
