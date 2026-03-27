# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # ─────────────────────────────────────────────
  # VM 1 — Gateway / Firewall
  # ─────────────────────────────────────────────
  config.vm.define "gateway" do |gw|
    gw.vm.box      = "ubuntu/jammy64"
    gw.vm.hostname = "gateway"

    # Interface DMZ
    gw.vm.network "private_network", ip: "192.168.100.1",
      virtualbox__intnet: "dmz_net"

    # Interface LAN
    gw.vm.network "private_network", ip: "192.168.10.1",
      virtualbox__intnet: "lan_net"

    gw.vm.provider "virtualbox" do |vb|
      vb.name   = "gateway"
      vb.memory = "512"
      vb.cpus   = 1
    end

    # Provisioning minimal pour Ansible (Python)
    gw.vm.provision "shell", inline: <<-SHELL
      apt-get update -qq
      apt-get install -y python3 python3-pip
    SHELL
  end

  # ─────────────────────────────────────────────
  # VM 2 — Serveur Web (DMZ)
  # ─────────────────────────────────────────────
  config.vm.define "webserver" do |web|
    web.vm.box      = "ubuntu/jammy64"
    web.vm.hostname = "webserver"

    # Interface DMZ
    web.vm.network "private_network", ip: "192.168.100.10",
      virtualbox__intnet: "dmz_net"

    web.vm.provider "virtualbox" do |vb|
      vb.name   = "webserver"
      vb.memory = "1024"
      vb.cpus   = 1
    end

    web.vm.provision "shell", inline: <<-SHELL
      apt-get update -qq
      apt-get install -y python3 python3-pip
      # Route par défaut via Gateway DMZ
      ip route add default via 192.168.100.1 || true
    SHELL
  end

  # ─────────────────────────────────────────────
  # VM 3 — Serveur Base de Données (LAN)
  # ─────────────────────────────────────────────
  config.vm.define "dbserver" do |db|
    db.vm.box      = "ubuntu/jammy64"
    db.vm.hostname = "dbserver"

    # Interface LAN
    db.vm.network "private_network", ip: "192.168.10.10",
      virtualbox__intnet: "lan_net"

    db.vm.provider "virtualbox" do |vb|
      vb.name   = "dbserver"
      vb.memory = "1024"
      vb.cpus   = 1
    end

    db.vm.provision "shell", inline: <<-SHELL
      apt-get update -qq
      apt-get install -y python3 python3-pip
      # Route par défaut via Gateway LAN
      ip route add default via 192.168.10.1 || true
    SHELL
  end

end
