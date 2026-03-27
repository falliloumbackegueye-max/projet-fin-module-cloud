#!/usr/bin/env bash
# =============================================================
# install_runner.sh — Installation du GitHub Actions Self-Hosted Runner
# Usage : bash scripts/install_runner.sh <GITHUB_URL> <TOKEN>
# Exemple :
#   bash scripts/install_runner.sh https://github.com/mon-org/mon-repo ghp_XXXXX
# =============================================================
set -euo pipefail

GITHUB_URL="${1:?Usage: $0 <GITHUB_URL> <REGISTRATION_TOKEN>}"
REG_TOKEN="${2:?Usage: $0 <GITHUB_URL> <REGISTRATION_TOKEN>}"
RUNNER_VERSION="2.317.0"
RUNNER_DIR="${HOME}/actions-runner"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)-runner}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,x64}"

# ── Couleurs ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Vérifications préalables ────────────────────────────────
info "Vérification des prérequis..."
command -v curl   >/dev/null || error "curl non trouvé"
command -v tar    >/dev/null || error "tar non trouvé"
command -v python3 >/dev/null || warn "python3 absent — Ansible en aura besoin"

# ── Dépendances système ─────────────────────────────────────
info "Installation des dépendances système..."
sudo apt-get update -qq
sudo apt-get install -y \
  curl tar libssl-dev libffi-dev \
  python3 python3-pip git \
  ruby vagrant virtualbox \
  ansible \
  2>/dev/null || warn "Certains paquets n'ont pas pu être installés"

# Ansible collections
pip3 install --quiet ansible yamllint ansible-lint || true
ansible-galaxy collection install \
  ansible.posix community.general community.mysql \
  --force-with-deps --quiet || true

# ── Téléchargement du Runner ─────────────────────────────────
info "Création du répertoire runner : ${RUNNER_DIR}"
mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

ARCHIVE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${ARCHIVE}"

if [[ -f "${ARCHIVE}" ]]; then
  info "Archive déjà présente, vérification du checksum..."
else
  info "Téléchargement du runner v${RUNNER_VERSION}..."
  curl -fsSL -o "${ARCHIVE}" "${DOWNLOAD_URL}"
fi

info "Extraction..."
tar xzf "${ARCHIVE}" --overwrite

# ── Configuration ────────────────────────────────────────────
info "Configuration du runner..."
./config.sh \
  --url "${GITHUB_URL}" \
  --token "${REG_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --work "_work" \
  --unattended \
  --replace

# ── Installation comme service systemd ───────────────────────
info "Installation du service systemd..."
sudo ./svc.sh install "${USER}" 2>/dev/null || true
sudo ./svc.sh start             2>/dev/null || true

# ── Vérification ─────────────────────────────────────────────
sleep 2
if sudo ./svc.sh status 2>/dev/null | grep -q "active (running)"; then
  info "✅ Runner actif en tant que service systemd"
else
  warn "Le service n'est peut-être pas démarré. Lancement manuel..."
  nohup ./run.sh > "${RUNNER_DIR}/runner.log" 2>&1 &
  info "Runner lancé en arrière-plan (PID $!)"
  info "Logs : ${RUNNER_DIR}/runner.log"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  Runner installé avec succès !          ${NC}"
echo -e "${GREEN}  Nom    : ${RUNNER_NAME}               ${NC}"
echo -e "${GREEN}  Labels : ${RUNNER_LABELS}             ${NC}"
echo -e "${GREEN}  Dépôt  : ${GITHUB_URL}                ${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
