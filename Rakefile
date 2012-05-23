require 'open3'
require 'colorize'
require 'json'

config = YAML.load_file('config.yml')

def c command
  stdin, stdout, stderr, wait_thr = Open3.popen3("(#{command} 2>&1 1>&3 | tee errorlog ) 3>&1")

  passed = true
  log_complete = []
  log_error = []

  while (line = stdout.gets)
    if File.readlines('errorlog').include? line
      log_error << line
      line = line.red
      passed = false
    end
    log_complete << line
    $stdout.write line
  end

  {:passed => passed, :log_complete => log_complete.join('\n'), :log_error => log_error.join('\n')}
end

result = {}

desc 'Compile on all VMs'
task :test do
  start_time = Time.now
  result[:name] = "run_#{start_time.strftime('%Y-%m-%d_%H%M%S')}"
  result[:start_time] = start_time
  result[:systems] = []
  unless File.directory?("./of_source")
    puts '# copying openFrameworks source'
    c "cp -r #{config['of_source']} ./of_source"
    c "rm -rf ./of_source/.git"
  end
  puts '## Compiling on all VMs...'
  config['boxes'].each do |box|
    box_result = {:name => box['name']}
    box_result[:tests] = []
    puts "# making fresh OF copy for #{box['name']}"
    c "cp -r ./of_source #{config['share_folder']}/of"
    c "vagrant up #{box['name'].gsub('-',"_")}"
    puts "# running pre command..."
    c "vagrant ssh #{box['name'].gsub('-',"_")} -c '#{box['pre_command']}'"
    puts "# running install scripts..."
    box['install_scripts'].each do |script|
      res = c "vagrant ssh #{box['name'].gsub('-',"_")} -c 'sudo /vagrant/of/scripts/linux/#{box['distro']}/#{script}'"
      box_result[:tests] << {:name => script}.merge!(res)
    end
    result[:systems] << box_result
    c "rm -rf ./of"
    c "vagrant halt #{box['name'].gsub('-',"_")}"
  end
  result[:end_time] = Time.now

  File.open("#{result[:name]}.json", 'w+') {|f| f.write(JSON.pretty_generate(result)) }
end
