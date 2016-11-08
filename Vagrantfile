# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"

  config.vm.provider "virtualbox" do |v|
    v.customize [
      "modifyvm", :id,
      "--ioapic", "on",
      "--cpus", "4",
      "--memory", "4096"
    ]
  end
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #

  config.vm.provision "shell", inline: <<-SHELL
  # install required packages
    apt-get update
    apt-get install -y isolinux xorriso bsdtar \
                devscripts debhelper lintian dh-make vim gdebi build-essential \
                vim

  # provision bashrc
  if ! grep -q 'source /vagrant/conf/user.conf' /home/vagrant/.bashrc; then
    cat <<EOF >> /home/vagrant/.bashrc
source /vagrant/conf/user.conf
WORKSPACE=~/workspace
export DEBEMAIL DEBFULLNAME WORKSPACE
EOF
  fi
  SHELL
end
