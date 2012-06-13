# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
of_config = YAML.load_file('config.yml')

Vagrant::Config.run do |config|
  of_config['boxes'].each do |box|
    config.vm.define box['name'].to_sym do |box_config|
      box_config.vm.box = box['name']
      box_config.vm.share_folder "vagrant", "/vagrant", of_config['share_folder']
      box_config.vm.customize do |vm|
        vm.cpu_count = of_config['cpu_count']
        vm.memory_size = of_config['memory_size']
      end
      #box_config.vm.boot_mode = :gui
    end
  end
end
