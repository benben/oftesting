# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
of_config = YAML.load_file('config.yml')

Vagrant::Config.run do |config|
  of_config['boxes'].each do |box|
    config.vm.define box['name'].to_sym do |box_config|
      box_config.vm.box = box['name']
      box_config.vm.share_folder "foo", "/vagrant", of_config['share_folder']
      #box_config.vm.boot_mode = :gui
    end
  end

  # config.vm.define :"vagrant-fedora16-gnome-32bit" do |box_config|
  #   box_config.vm.box = "vagrant-fedora16-gnome-32bit"
  #   box_config.vm.share_folder "foo", "/vagrant", of_config['share_folder']
  #   #box_config.vm.boot_mode = :gui
  # end

  # config.vm.define :"vagrant-ubuntu-12.04-32bit" do |box_config|
  #   box_config.vm.box = "vagrant-ubuntu-12.04-32bit"
  #   box_config.vm.share_folder "foo", "/vagrant", of_config['share_folder']
  #   #box_config.vm.boot_mode = :gui
  # end
end
