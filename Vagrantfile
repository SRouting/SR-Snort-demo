# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
	# Ingress node configuration
	config.vm.define "ingress" do |ingress|
		ingress.vm.box = "srouting/srv6-net-prog"
		ingress.vm.box_version = "0.4.14"
		ingress.vm.synced_folder(".", nil, :disabled => true, :id => "vagrant-root")
		ingress.vm.network "private_network", ip: "12::1", virtualbox__intnet: "net12"
		ingress.vm.provider "virtualbox" do |virtualbox|
			virtualbox.memory = "512"
			virtualbox.customize ['modifyvm', :id, '--cableconnected1', 'on']
			virtualbox.customize ['modifyvm', :id, '--cableconnected2', 'on']
		end
	        ingress.vm.provision "shell", path: "config/config_ingress.sh"
	end

	# Node R2 configuration
	config.vm.define "nfv" do |nfv|
		nfv.vm.box = "srouting/srv6-net-prog"
		nfv.vm.box_version = "0.4.14"
                nfv.vm.synced_folder(".", nil, :disabled => true, :id => "vagrant-root")
		nfv.vm.network "private_network", ip: "12::2", virtualbox__intnet: "net12"
		nfv.vm.network "private_network", ip: "23::2", virtualbox__intnet: "net23"
		nfv.vm.provider "virtualbox" do |virtualbox|
			virtualbox.memory = "512"
			virtualbox.cpus = "1"
			virtualbox.customize ['modifyvm', :id, '--cableconnected1', 'on']
			virtualbox.customize ['modifyvm', :id, '--cableconnected2', 'on']
			virtualbox.customize ['modifyvm', :id, '--cableconnected3', 'on']
		end
                nfv.vm.provision "shell", path: "config/config_nfv.sh"
	end

        # Node R3 configuration
        config.vm.define "egress" do |egress|
                egress.vm.box = "srouting/srv6-net-prog"
                egress.vm.box_version = "0.4.14"
                egress.vm.synced_folder(".", nil, :disabled => true, :id => "vagrant-root")
                egress.vm.network "private_network", ip: "fc00:23::3", virtualbox__intnet: "net23"
                egress.vm.provider "virtualbox" do |virtualbox|
                        virtualbox.memory = "512"
                        virtualbox.customize ['modifyvm', :id, '--cableconnected1', 'on']
                        virtualbox.customize ['modifyvm', :id, '--cableconnected2', 'on']
                end
                egress.vm.provision "shell", path: "config/config_egress.sh"
        end

end
