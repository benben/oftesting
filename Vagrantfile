# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
of_config = YAML.load_file('config.yml')

Vagrant::Config.run do |config|
  of_config['boxes'].each do |box|
    config.vm.define box['name'].to_sym do |box_config|
      box_config.vm.box = box['name']
      if box['distro'] !~ /osx/
        box_config.vm.share_folder 'vagrant', '/vagrant', of_config['share_folder']
      end
      box_config.vm.customize ['modifyvm', :id, '--ioapic', 'on', '--memory', of_config['memory_size'], '--cpus', of_config['cpu_count']]
      box_config.vbguest.auto_update = false
      #box_config.vm.boot_mode = :gui
    end
  end
end
