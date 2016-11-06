# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end

  ## need to copy all key.pub as authorized_keys in /root/.ssh/

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  
  #config.vm.box = "ubuntu/trusty64"
  #config.vm.box = "opensuse/openSUSE-42.1-x86_64"
  config.vm.box = "fedora/24-cloud-base"
  #config.vm.box = "boxcutter/fedora24"

  config.vm.define :elkserver do |elkserver|
    # Hostname to set on the node
    elkserver.vm.host_name="elkserver"

    # Hostonly network interface, used for internode communication
    elkserver.vm.network "private_network", ip: "192.168.98.101"
    elkserver.vm.network "forwarded_port", guest: 80, host: 8080

  end

  config.vm.define :elkclient do |elkclient|
    # Hostname to set on the node
    elkclient.vm.host_name="elkclient"

    # Hostonly network interface, used for internode communication
    elkclient.vm.network "private_network", ip: "192.168.98.102"
    elkclient.vm.network "forwarded_port", guest: 80, host: 8081
  end
end
