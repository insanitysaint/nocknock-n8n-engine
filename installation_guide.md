# Installation guide (for people and for AI assistants)

This file is written so that a person **or an LLM agent** can follow it from top to bottom and end with a working Nocknock outreach engine. Every step has a command, the result you should see, and what to do if you do not see it. A pretty PDF version with screenshots is in [`docs/Nocknock-Setup-Guide.pdf`](docs/Nocknock-Setup-Guide.pdf).

## 0. Rules for an AI agent running this guide

1. Work through the steps **in order**. Do not skip a verification line. If a check fails, use the "If it fails" row for that step before moving on.
2. **Never put real secrets in chat, in logs, in commits or in this repository.** Passwords go only into the local `.env` file, which is git-ignored.
3. **Ask the human** for the values in section 2 (they cannot be guessed). Do not invent an SMTP password, an app password or an API key.
4. Keep `TEST_MODE=true` until the human has received a test email and says to go live. Changing it to `false` is the only action that can email real people, so it needs an explicit yes.
5. Do not open port 5678 to the internet. On a server, only Caddy (ports 80 and 443) is public.
6. Do not run anything that deletes data (`docker compose down -v`, `rm -rf n8n-files`) without the human confirming.
7. If the human's machine is Windows, use PowerShell syntax where a command differs (shown as `PowerShell:` below).

## 1. What this is

A self-hosted cold-email engine. It runs the open-source workflow tool **n8n** in **Docker**, with a browser **cockpit** on top. You add leads, approve them, and it emails a few per day while each lead's office is open, follows up twice and stops when someone replies. Leads, the sent log and your mailbox password stay on your own machine or server.

Pick **one** install path:

| Path | Use it when | Time |
|---|---|---|
| **A. Local with Docker** | You want to try it, test it, or run it from your own computer | 10 minutes |
| **B. Oracle Cloud (free server)** | You want it running day and night with HTTPS and a login | 30 minutes |

Do path A first even if you want B. It proves your mailbox settings before you rent a server.

## 2. What the human must provide

Collect these **before** starting. Mark each as done.

| # | Item | Where to get it |
|---|---|---|
| 1 | A computer with internet, and a terminal | Windows: PowerShell. Mac/Linux: Terminal |
| 2 | **Docker Desktop** (path A) or a server account (path B) | https://www.docker.com/products/docker-desktop/ |
| 3 | **Git** | https://git-scm.com/downloads (or download the ZIP from the repo instead) |
| 4 | A **sending mailbox on a domain you own** | Zoho Mail, Google Workspace, Microsoft 365, Fastmail. Do not use your personal inbox for cold email |
| 5 | An **app password** for that mailbox | See section 7 |
| 6 | The mailbox's **SMTP host and port** (and IMAP host if you want replies shown) | See the table in section 7 |
| 7 | A **booking link** (Cal.com or Calendly) | Free Cal.com account |
| 8 | One or two sentences about **who you are and what you sell** | Your own words |
| 9 | A **postal address** for the email footer | Required by US, UK and EU commercial-email rules; a PO box or registered office is fine |
| 10 | *(optional)* a free **Reoon** API key | https://emailverifier.reoon.com (free credits, no card) |

## 3. Path A: run it locally with Docker

### A1. Install and start Docker

1. Install Docker Desktop and open it. Wait until it says it is running.
2. Check:

```bash
docker --version
docker compose version
```

Expected: two version lines (Docker 24 or newer, Compose v2). If it says `command not found`, Docker is not installed or not on your PATH: reopen the terminal, or reinstall. If it says it cannot connect to the daemon, Docker Desktop is not running yet.

### A2. Get the repo

```bash
git clone https://github.com/insanitysaint/nocknock-n8n-engine.git
cd nocknock-n8n-engine
```

No git? Download the ZIP from the repository page ("Code" > "Download ZIP"), unzip it, and open a terminal in the folder that contains `docker-compose.yml`.

Check: `ls docker-compose.yml` (PowerShell: `dir docker-compose.yml`) shows the file.

### A3. Create your settings file

```bash
cp .env.example .env
```

PowerShell: `Copy-Item .env.example .env`

### A4. Fill in `.env`

Open `.env` in any text editor. Set these lines (keep everything else as it is):

| Key | Value |
|---|---|
| `TEST_MODE` | `true` (leave it) |
| `TEST_ADDRESS` | your own email address; every test email lands here |
| `SENDER_EMAIL` | the sending mailbox, e.g. `you@yourdomain.com` |
| `SENDER_NAME`, `SENDER_ROLE`, `SENDER_COMPANY`, `SENDER_WEBSITE` | how the email is signed |
| `OFFER` | one or two sentences about who you are and what you sell |
| `BOOKING_LINK` | your Cal.com / Calendly link |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER` | from the table in section 7 |
| `SMTP_PASSWORD` | the **app password** (not your normal password) |
| `SMTP_SECURE` | `true` for port 465, `false` for port 587 |
| `IMAP_HOST` | optional; fill in to show replies in the cockpit (section 7) |
| `DAILY_LIMIT` | `5` |
| `TZ` | your time zone, e.g. `Asia/Kolkata`, `Europe/London`, `America/New_York` |

Also check that nothing else on the computer uses port 5678 (another n8n, for example). If it does, add `N8N_PORT=5679` to `.env` and use that number everywhere below instead of 5678.

### A5. Start it

```bash
docker compose up -d
docker compose logs -f
```

The first start downloads n8n (about 1 GB) and can take several minutes. Wait for these lines, then press Ctrl+C to stop watching (the engine keeps running):

```
[kit] seeded lead_inbox.csv
[kit] imported workflows
[kit] ready. Cockpit: http://localhost:5678/webhook/cockpit
```

Then wait about a minute more for n8n to finish starting.

| If it fails | Fix |
|---|---|
| `unable to find user node` | An old copy of the kit pinned the broken n8n image `2.35.7`. Run `git pull`, or edit `docker-compose.yml` and change the image tag `2.35.7` to `2.42.5`, then `docker compose down` and `docker compose up -d` |
| `port is already allocated` | Set `N8N_PORT=5679` in `.env`, then `docker compose up -d --force-recreate` |
| `permission denied` in `n8n-files` (Linux) | `sudo chown -R 1000:1000 n8n-files` |
| Download stops with `unexpected EOF` | Network blip; run `docker compose up -d` again |

### A6. Open the cockpit and take the tour

1. Open http://localhost:5678/webhook/cockpit (use your own port if you changed it). Expected: a dark page titled **Overview** with eight demo leads.
2. Optionally open http://localhost:5678 and create the n8n owner account (any email and password; it is local to your machine). You only need this to look inside the workflows.
3. In the cockpit open **Pipeline** and approve one demo lead.
4. Send a test email: in n8n (http://localhost:5678) open the workflow **Outsorcerer Outreach Engine**, click the node **4 Sender - Weekdays 11:00**, then **Execute workflow**.
5. Check the inbox of `TEST_ADDRESS`. Expected: an email whose subject starts with `[TEST for ...]`. Check the spam folder too.

Test mode records nothing as sent, so you can repeat this as often as you like.

| If it fails | Fix |
|---|---|
| "set TEST_ADDRESS" error | Set `TEST_ADDRESS` in `.env`, then `docker compose up -d --force-recreate` |
| SMTP or authentication error | Wrong host, port or password. Use the **app password**; port 465 needs `SMTP_SECURE=true`, 587 needs `false` |
| No email, no error | Check spam. Check the demo lead is approved. Run `docker compose logs --tail 50` |

After any change to `.env` always run `docker compose up -d --force-recreate`.

## 4. Path B: run it on Oracle Cloud (free server)

Do path A first. Then:

### B1. Create the server

1. Create an Oracle Cloud account (https://www.oracle.com/cloud/free/). It asks for a card to verify you; the Always Free resources are not charged. Never click "Upgrade".
2. Console > **Compute > Instances > Create instance**.
3. Image **Canonical Ubuntu 24.04**. Shape **Ampere A1 Flex** with 2 OCPU and 12 GB memory (free allowance is 4 OCPU / 24 GB). If Oracle says "Out of host capacity", retry in a few minutes or pick another availability domain. The 1 GB AMD micro shape also works but is slow.
4. Keep "Assign a public IPv4 address" on. Paste your **SSH public key** (or let Oracle create one and download the private key). Create the instance.
5. Open ports 80 and 443: **Networking > Virtual Cloud Networks > your VCN > Security Lists > Default > Add Ingress Rules**. Source `0.0.0.0/0`, protocol TCP, destination port `80`. Repeat for `443`. Do **not** open 5678.
6. Copy the **public IP** of the instance.

Check: `ssh ubuntu@<IP>` (add `-i path/to/private-key` if Oracle made the key) gives a shell.

### B2. Put the repo on the server and prepare it

On the server:

```bash
git clone https://github.com/insanitysaint/nocknock-n8n-engine.git
cd nocknock-n8n-engine
bash oracle/setup-vm.sh
```

The script installs Docker, opens ports 80 and 443 in the VM firewall, adds 4 GB swap and prepares the data folder. When it ends, **log out and back in** (`exit`, then `ssh` again) so the Docker group applies. Check: `docker ps` runs without `sudo`.

### B3. Settings for the server

```bash
cd nocknock-n8n-engine
cp .env.example .env
cat oracle/oracle.env.example >> .env
nano .env
```

Fill in the same values as in A4, using `TEST_MODE=true`. Then set the four server lines at the bottom of the file:

| Key | Value |
|---|---|
| `COMPOSE_FILE` | leave as it is (`docker-compose.yml:oracle/docker-compose.oracle.yml`) |
| `DOMAIN` | your own domain pointed at the server's IP (an `A` record), or with no domain use your IP with dashes plus `.sslip.io`, e.g. IP `129.151.10.20` gives `129-151-10-20.sslip.io` |
| `APP_USER` | the login name you want, e.g. `admin` |
| `APP_PASSWORD_HASH` | a hash of a long password, made with the command below; keep the single quotes |

Make the hash (pick a long password, type it between the single quotes):

```bash
docker run --rm caddy caddy hash-password --plaintext 'a-long-password-you-choose'
```

Paste the output (starts with `$2a$`) into `.env` as `APP_PASSWORD_HASH='...'`. Oracle only allows mail on ports 465, 587 and 993 (port 25 is blocked), so use those for SMTP and IMAP. Save with Ctrl+O, Enter, Ctrl+X.

### B4. Start it

```bash
docker compose up -d
docker compose logs -f caddy
```

Wait for a line saying a certificate was obtained for your domain (up to a minute or two), then Ctrl+C. Open `https://<DOMAIN>/` in a browser. It asks for `APP_USER` and your password, then shows the cockpit.

| If it fails | Fix |
|---|---|
| Browser cannot connect | Port 80/443 not open: re-check B1 step 5 and `sudo iptables -L INPUT -n --line-numbers` for ACCEPT rules on 80 and 443 |
| Certificate error or "not secure" | The domain does not point at the IP yet, or you used `localhost`. Wait a few minutes, check the `A` record |
| `set DOMAIN in .env` / `APP_PASSWORD_HASH` | Missing in `.env`; add and run `docker compose up -d` again |
| n8n is slow or restarts on the 1 GB shape | Normal for 1 GB. Use the Ampere shape, or wait a few minutes after a restart |

### B5. Send a test email from the server

Do the same as A6 steps 3 to 5. The n8n editor is not public; to open it use an SSH tunnel: `ssh -L 5678:127.0.0.1:5678 ubuntu@<IP>`, then browse to http://localhost:5678 on your own computer.

## 5. Add your leads (free)

The engine does not find leads; you give it a list. Everything below is free.

**Format:** a header row and these columns (any order): `Company`, `Website`, `Email`, `First Name`, `Location`, `Notes`, `Score`. `Location` ("Dubai, UAE") sets the time zone the engine uses for the send window, so be specific. Use **public business emails** only (for example `hello@` or a named person on the company's own domain).

**Where to find them, no cost:**

1. **An AI assistant with web search** (Perplexity, Gemini or ChatGPT free tiers). Use **Prompt A** in `docs/PERSONA_SCRAPER_PROMPT.md`: fill in the persona brief, paste the prompt, and the answer comes back as a table the cockpit understands.
2. **Google Maps** by hand: search "your business type + city", open each result, copy company, website and location into a sheet. For volume, free tools: **OpenStreetMap** (Overpass Turbo, https://overpass-turbo.eu) lists businesses with websites for free; Apify's free monthly credit runs a Google Maps scraper.
3. **Directories**: Clutch, GoodFirms, DesignRush, Sortlist, Product Hunt makers and local chamber of commerce lists show company, site and city.
4. **Build your own scraper:** give **Prompt B** in `docs/PERSONA_SCRAPER_PROMPT.md` to an AI coding assistant. It builds a tool that follows the guardrails in that file.
5. **No email column?** Leave it blank; the engine tries to find a public contact address on the company's own website.

**Check the addresses before sending (free):** make a free account at https://emailverifier.reoon.com (100 credits on sign-up and about 20 a day after), paste the addresses into its bulk checker, and delete the ones it marks invalid. Fewer bounces protect your sender reputation.

**Upload:** cockpit > **Upload leads** > drop the CSV (or paste the table) > pick a campaign > **Add**. New leads land in **Pipeline** as "review". Nothing is emailed until you approve a lead.

## 6. Warm up the mailbox (free, no paid tool)

A new domain or mailbox that suddenly sends many emails goes to spam. Warm-up means building a normal sending history slowly. You can do it at no cost:

1. **DNS first (day 0).** On the sending domain set SPF, DKIM and DMARC records (your mail host shows the exact values in its admin panel). Verify them for free at https://mxtoolbox.com/SuperTool.aspx and send one email to https://www.mail-tester.com (free score; aim for 9 or 10 of 10).
2. **Real mail, days 1 to 14.** Send a few normal one-to-one emails a day from the new mailbox to people you know (friends, colleagues, your other addresses), ask them to **reply**, and reply back. Mark any message that lands in spam as "Not spam". Real conversations are what builds reputation.
3. **Ramp the engine slowly.** Keep `DAILY_LIMIT=5` for the first two weeks. Then raise it by about 5 every few days if bounces stay under 2% and nobody marks you as spam. A sensible ceiling for one new mailbox is 20 to 30 a day.
4. **Send at human hours, every working day.** The engine already waits for the lead's office hours.
5. **Watch the signals.** Free: Google Postmaster Tools (https://postmaster.google.com) for domain reputation, and the cockpit's bounce count. If bounces pass 3 in the last 20, stop, clean the list and slow down.
6. **Use a separate domain.** Send from a secondary domain (for example `getyourbrand.com`), not your main business domain, so a spam problem never touches your main email.

Automated warm-up services exist but are paid; they are optional. The steps above work without them, only more slowly.

## 7. API keys, app passwords and where they go

Nocknock has no hosted account: the only "keys" are your mailbox login and optional extras. All of them go into `.env` and nowhere else. **Never use your normal mailbox password; create an app password.**

| Provider | Create the app password | `SMTP_HOST` / `SMTP_PORT` / `SMTP_SECURE` | `IMAP_HOST` |
|---|---|---|---|
| **Zoho Mail** | https://accounts.zoho.com (or `.in`, `.eu` for your region) > Security > App Passwords > Generate. Also enable IMAP in Mail settings > Mail Accounts | `smtp.zoho.com` (India: `smtp.zoho.in`) / 465 / `true` | `imap.zoho.com` (India: `imap.zoho.in`) |
| **Google Workspace / Gmail** | Turn on 2-Step Verification, then https://myaccount.google.com/apppasswords > create one | `smtp.gmail.com` / 465 / `true` | `imap.gmail.com` |
| **Microsoft 365 / Outlook** | An admin must allow "Authenticated SMTP" for the mailbox; use an app password if MFA is on | `smtp.office365.com` / 587 / `false` | `outlook.office365.com` |
| **Fastmail** | Settings > Privacy & Security > App passwords | `smtp.fastmail.com` / 465 / `true` | `imap.fastmail.com` |

Put it in `.env` like this (example values only):

```
SMTP_HOST=smtp.zoho.com
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=you@yourdomain.com
SMTP_PASSWORD=the-app-password
IMAP_HOST=imap.zoho.com
```

Reply detection needs `IMAP_HOST`; leave it empty to switch it off. Optional keys: your Cal.com link goes in `BOOKING_LINK` (a link, not a secret); a Reoon key is used on the Reoon website for list checking and is not needed in `.env` for this kit. After editing `.env` run `docker compose up -d --force-recreate`.

## 8. Go live (only when the human says so)

All of these must be true: a test email arrived and looked right; SPF, DKIM and DMARC pass; `OFFER`, `BOOKING_LINK` and the `SENDER_*` lines contain real text (the engine refuses to send while they hold `[placeholders]`); a postal address is in the footer text; at least one real lead is approved.

1. In `.env` set `TEST_MODE=false` and keep `DAILY_LIMIT=5`.
2. `docker compose up -d --force-recreate`
3. Approve leads in the cockpit. The engine sends up to the daily limit while each lead's office is open (09:00 to 11:00 local, working days). Email 2 follows after 5 days and email 3 after 5 more, unless the person replied. A reply, bounce or opt-out stops the sequence.

Verify: cockpit **Overview** shows "Emails sent" go above 0 and the recipient list matches the leads you approved.

## 9. Everyday commands

```bash
docker compose up -d                    # start
docker compose stop                     # stop, keeps all data
docker compose logs -f                  # watch the log
docker compose up -d --force-recreate   # apply changes to .env
git pull && docker compose up -d --force-recreate   # update the kit
```

Your data is plain files in `n8n-files/` (`lead_inbox.csv`, `sent_log.csv`, `cockpit.json`). Back it up by copying that folder. `docker compose down -v` deletes n8n's database too; do not run it unless you want a clean start.

## 10. Responsible use

This is for **B2B** outreach to business addresses. Include a real postal address, honour opt-outs at once, never buy or scrape personal addresses, and follow the law where your leads live (CAN-SPAM, UK PECR, EU rules, CASL). You are responsible for how you use it. See `docs/PRODUCT.md`.
