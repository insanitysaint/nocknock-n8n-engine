#!/usr/bin/env bash
# One-time setup for a fresh Oracle Cloud Ubuntu VM. Run it from the folder that holds docker-compose.yml:
#   bash oracle/setup-vm.sh
# Keep this file LF-only (see .gitattributes).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Installing Docker"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
fi

echo "==> Opening ports 80 and 443 in the VM firewall"
# Oracle's Ubuntu images ship with iptables rules that reject everything except SSH.
# You must ALSO open 80 and 443 in the VCN security list in the Oracle console (guide, step 3).
for port in 80 443; do
  if ! sudo iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
    sudo iptables -I INPUT 6 -p tcp --dport "$port" -j ACCEPT
  fi
done
sudo apt-get install -y iptables-persistent >/dev/null 2>&1 || true
sudo netfilter-persistent save >/dev/null 2>&1 || sudo sh -c 'iptables-save > /etc/iptables/rules.v4'

echo "==> Adding 4 GB of swap (the free 1 GB VM runs out of memory without it)"
if ! swapon --show | grep -q swapfile; then
  sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile >/dev/null && sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

echo "==> Preparing the data folder (n8n runs as user 1000 inside its container)"
mkdir -p n8n-files
sudo chown -R 1000:1000 n8n-files

echo
echo "Done. Log out and back in once so the docker group applies, then continue with step 6 of the guide."
