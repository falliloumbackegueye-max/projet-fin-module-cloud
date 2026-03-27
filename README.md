# Architecture 3-Tiers — Projet Fin de Module

Infrastructure réseau virtualisée, sécurisée et automatisée.

## 🏗️ Schéma réseau

```
Internet
   │
   │ (NAT — enp0s3)
   ▼
┌──────────────────────────────┐
│   Gateway / Firewall         │
│   DMZ : 192.168.100.1        │
│   LAN : 192.168.10.1         │
│   (iptables + ip_forward)    │
└──────┬──────────────┬────────┘
       │              │
  DMZ (100.0/24)  LAN (10.0/24)
       │              │
       ▼              ▼
┌────────────┐  ┌────────────┐
│ Web Server │  │ DB Server  │
│ 100.10     │  │ 10.10      │
│ Nginx+Node │  │ MySQL      │
└────────────┘  └────────────┘
```

## 📋 Prérequis

- VirtualBox ≥ 7.0
- Vagrant ≥ 2.4
- Ansible ≥ 2.15
- Python 3.10+
- Un compte GitHub (pour le Runner CI/CD)

## 🚀 Démarrage rapide

### 1. Démarrer les VMs

```bash
vagrant up
```

### 2. Installer les collections Ansible

```bash
ansible-galaxy collection install ansible.posix community.general community.mysql
```

### 3. Tester la connectivité

```bash
ansible all -i ansible/inventory.ini -m ping
```

### 4. Déployer l'infrastructure complète

```bash
ansible-playbook -i ansible/inventory.ini ansible/site.yml
```

### 5. Installer le Self-Hosted Runner (GitHub Actions)

```bash
# Récupérer le token sur : Settings > Actions > Runners > New self-hosted runner
bash scripts/install_runner.sh https://github.com/VOTRE-ORG/VOTRE-REPO VOTRE_TOKEN
```

## 🔐 Variables secrètes GitHub

Configurer dans **Settings → Secrets → Actions** :

| Secret        | Description                          |
|---------------|--------------------------------------|
| `DB_PASSWORD` | Mot de passe MySQL de l'utilisateur  |
| `APP_REPO`    | URL Git du dépôt applicatif          |

## 📂 Structure du projet

```
/
├── Vagrantfile                   # Infrastructure VirtualBox (3 VMs)
├── .github/workflows/
│   └── deploy.yml                # Pipeline CI/CD (lint + deploy)
├── ansible/
│   ├── inventory.ini             # IPs et accès SSH des VMs
│   └── site.yml                  # Playbook principal (gateway, web, db)
├── app/
│   ├── index.js                  # Application Node.js Express
│   └── package.json
└── scripts/
    └── install_runner.sh         # Installation du Runner auto-hébergé
```

## 🔒 Sécurité

- **MySQL** n'accepte les connexions qu'depuis `192.168.100.10` (IP du Web).
- **iptables** sur la Gateway bloque tout trafic LAN→DMZ sauf le retour TCP établi.
- Le port `3306` est bloqué sur le DB server pour toute source hors DMZ.
- Aucune règle `ssh` ouverte sur les VMs en production (accès via Vagrant SSH uniquement).

## 🧪 Tests manuels

```bash
# Nginx répond sur le Web
curl http://192.168.100.10

# Santé de la DB depuis le Web
curl http://192.168.100.10/health

# Depuis la Gateway — test routage
vagrant ssh gateway
ping 8.8.8.8
```
