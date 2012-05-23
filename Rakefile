require 'open3'
require 'colorize'

config = YAML.load_file('config.yml')

def c command
  stdin, stdout, stderr, wait_thr = Open3.popen3("(#{command} 2>&1 1>&3 | tee errorlog ) 3>&1")

  while (line = stdout.gets)
    if File.readlines('errorlog').include? line
      line = line.red
    end
    $stdout.write line
  end

  $stdin.flush
  $stdout.flush
  $stderr.flush
end

desc 'Compile on all VMs'
task :test do
  start_time = Time.now
  unless File.directory?("./of_source")
    puts '# copying openFrameworks source'
    c "cp -r #{config['of_source']} ./of_source"
    c "rm -rf ./of_source/.git"
  end
  puts '## Compiling on all VMs...'
  config['boxes'].each do |box|
    puts "# making fresh OF copy for #{box['name']}"
    c "cp -r ./of_source #{config['share_folder']}/of"
    c "vagrant up #{box['name'].gsub('-',"_")}"
    puts "# running pre command..."
    c "vagrant ssh #{box['name'].gsub('-',"_")} -c '#{box['pre_command']}'"
    puts "# running install scripts..."
    box['install_scripts'].each do |script|
      c "vagrant ssh #{box['name'].gsub('-',"_")} -c 'sudo /vagrant/of/scripts/linux/#{box['distro']}/#{script}'"
    end
    c "rm -rf ./of"
    c "vagrant halt #{box['name'].gsub('-',"_")}"
  end
end
