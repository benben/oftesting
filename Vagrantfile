# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
of_config = YAML.load_file('config.yml')

Vagrant::Config.run do |config|
  config.vm.define :vagrant_fedora16_gnome_32bit do |box_config|
    box_config.vm.box = "vagrant-fedora16-gnome-32bit"
    box_config.vm.share_folder "foo", "/vagrant", of_config['share_folder']
    #box_config.vm.box = "vagrant-fedora16-gnome-32bit"
  end
end
