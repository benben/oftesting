require 'bundler/setup'
require 'open3'

config = YAML.load_file('config.yml')

def shell_exec command
  # running the command, writing exit code to tmp/exit_code, writing all errors to tmp/errorlog, piping everything to stdout
  stdin, stdout, stderr, wait_thr = Open3.popen3("((#{command}; echo $? > tmp/exit_code) 2>&1 1>&3 | tee tmp/errorlog ) 3>&1")

  status = 'passed'
  log_complete = []
  log_error = []

  while (line = stdout.gets)
    if File.readlines('tmp/errorlog').include? line
      log_error << line
      line = line.red
      status = 'warning'
    end
    log_complete << line
    $stdout.write line
  end

  status = 'error' if File.read('tmp/exit_code').to_i != 0

  File.delete('tmp/errorlog')
  File.delete('tmp/exit_code')

  {:status => status, :log_complete => log_complete.join, :log_error => log_error.join}
end

def shell_exec_on box_name, command
  shell_exec "vagrant ssh #{box_name} -c '#{command}'"
end

result = {}

desc 'test everything on all VMs'
task :test do
  start_time = Time.now
  result[:name] = "run_#{start_time.strftime('%Y-%m-%d_%H%M%S')}"
  result[:start_time] = start_time
  result[:systems] = []
  unless File.directory?("tmp/of_source")
    puts '# copying openFrameworks source'
    shell_exec "cp -r #{config['of_source']} tmp/of_source"
    shell_exec "rm -rf tmp/of_source/.git"
  end
  puts '## compiling on all VMs...'
  config['boxes'].each do |box|
    box_result = {:name => box['name']}
    box_result[:tests] = []
    puts "# making fresh OF copy for #{box['name']}"
    shell_exec "rm -rf #{config['share_folder']}/of"
    shell_exec "cp -r tmp/of_source #{config['share_folder']}/of"
    puts "# starting the vm..."
    shell_exec "vagrant up #{box['name']}"
    puts "# running pre command..."
    shell_exec_on box['name'], "#{box['pre_command']}"

    #install scripts
    puts "# running install scripts..."
    box['install_scripts'].each do |script|
      res = shell_exec_on box['name'], "cd /vagrant/of/scripts/linux/#{box['distro']} && sudo ./#{script}"
      box_result[:tests] << {:name => script}.merge!(res)
    end

    #project generator (compile)
    puts "# compiling the project generator..."
    res = shell_exec_on box['name'], 'cd /vagrant/of/apps/devApps/projectGenerator && make'
    box_result[:tests] << {:name => 'projectGenerator'}.merge!(res)

    #project generator (run --allexamples)
    #puts "# running the project generator..."
    #res = shell_exec_on box['name'], 'cd /vagrant/of/apps/devApps/projectGenerator/bin && ./projectGenerator --allexamples'
    #box_result[:tests] << {:name => './projectGenerator --allexamples'}.merge!(res)

    #examples
    puts "## compiling all examples..."
    Dir["#{config['share_folder']}/of/examples/*/*/Makefile"].each do |makefile|
      makefile.gsub!(/^share\//, '/vagrant/')
      dir = File.dirname(makefile)
      name = dir.match /[^\/]+$/
      puts "# compiling #{name}..."
      res = shell_exec_on box['name'], "cd #{dir} && make"
      box_result[:tests] << {:name => name}.merge!(res)
    end

    result[:systems] << box_result

    puts "# deleting OF folder..."
    shell_exec "rm -rf #{config['share_folder']}/of"
    puts "# halting the vm..."
    shell_exec "vagrant halt #{box['name']}"
  end

  puts "## generating results..."
  result[:end_time] = Time.now
  dir_name = "testruns/#{result[:name]}"
  Dir.mkdir(dir_name)
  File.open("#{dir_name}/result.json", 'w+', encoding: Encoding::UTF_8) {|f| f.write(JSON.pretty_generate(result)) }
end

desc 'clean'
task :clean do
  %x[rm -rf tmp/*]
  %x[rm -rf share/of]
end
