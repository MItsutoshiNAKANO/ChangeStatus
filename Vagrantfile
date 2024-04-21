## @license AGPL-3.0-or-later
# SPDX-License-Identifier: AGPL-3.0-or-later

# You must repeat `vagrant reload --provision`

$script = <<-SCRIPT
  set -eux
  dnf -y upgrade
  # @see https://www.linuxtechi.com/install-virtualbox-guest-additions-on-rhel/
  # @see https://www.linuxtechi.com/how-to-install-ansible-on-rhel/
  dnf -y install kernel-devel ansible-core
  ansible-galaxy collection install ansible.posix
  ansible-playbook /vagrant/playbook.yaml
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "almalinux/9"
  config.vm.provider "virtualbox" do |v|
    v.memory = 6144
    v.cpus = 2
  end
  config.vm.provision "shell", inline: $script
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.trigger.after :up, :reload do |trigger|
    trigger.info = "Start httpd"
    trigger.run_remote = {inline: "systemctl start httpd.service"}
  end
end
