# Run the engine on Oracle Cloud (free)

This folder turns the starter kit into an always-on server with HTTPS and a login.

| File | What it does |
|---|---|
| `setup-vm.sh` | Installs Docker, opens ports 80 and 443 on the VM, adds swap and prepares the data folder. |
| `docker-compose.oracle.yml` | Adds Caddy (HTTPS and the login) and hides n8n behind it. |
| `Caddyfile` | Sends `/` to the cockpit and proxies only the cockpit and the intake form. |
| `oracle.env.example` | The extra settings: `COMPOSE_FILE`, `DOMAIN`, `APP_USER`, `APP_PASSWORD_HASH`. |

Follow the step-by-step guide: https://nocknock.vercel.app/guides/oracle-cloud

The short version, on the VM, from the folder that holds `docker-compose.yml`:

```bash
bash oracle/setup-vm.sh                       # once, then log out and back in
cp .env.example .env && cat oracle/oracle.env.example >> .env     # then edit .env
docker compose up -d
```

Stay in `TEST_MODE=true` until you have sent yourself a test email from the server.
