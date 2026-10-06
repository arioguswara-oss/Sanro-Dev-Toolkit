# Security

SANRO Dev Toolkit must remain safe to clone onto a clean development machine.

## Never commit or package

- `.env` files containing secrets
- database passwords
- API/OAuth client secrets or tokens
- session secrets
- hosting/cPanel credentials
- SSH private keys
- collector/production credentials
- sensitive database dumps or unnecessary customer data

Generated recovery ZIPs are source/tooling snapshots only. Credentials must be restored separately from an encrypted backup or secret manager.

## Safe repository content

Configuration may describe tool names, project directories, test commands, branch names, public repository URLs, and non-secret runtime requirements. It must not contain a live password, token, private key, or credential material.

## If a secret is committed accidentally

Stop using the exposed credential, rotate/revoke it through the owning service, remove it from current source, then clean repository history using an appropriate history-rewrite procedure. Deleting only the latest file is not sufficient once a secret has entered Git history.
