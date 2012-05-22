config = YAML.load_file('config.yml')

desc 'Compile on all VMs'
task :test do
  start_time = Time.now
  puts '## starting...'
  unless File.directory?("./of_source")
    puts '# copying openFrameworks source'
    system "cp -r #{config['of_source']} ./of_source"
    system "rm -rf ./of_source/.git"
  end
  puts '## Compiling on all VMs...'
  puts config.inspect
  config['boxes'].each do |box|
    puts "# making fresh of source copy for #{box['name']}"
    system "cp -r ./of_source ./of"
    system "vagrant up #{box['name'].gsub('-',"_")}"
    system "vagrant ssh #{box['name'].gsub('-',"_")} -c '#{box['pre_command']}'"
    system "vagrant ssh #{box['name'].gsub('-',"_")} -c 'sudo /vagrant/of/scripts/linux/#{box['distro']}/install_dependencies.sh'"
    system "rm -rf ./of"
    system "vagrant halt #{box['name'].gsub('-',"_")}"
  end
end
