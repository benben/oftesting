require 'bundler/setup'
require 'open3'
require 'colored'
require 'json'

config = YAML.load_file('config.yml')

def shell_exec command
  begin
    Timeout::timeout(config['script_timeout']) do
      # running the command, writing exit code to tmp/exit_code, writing all errors to tmp/errorlog, piping everything to stdout
      stdin, stdout, stderr, wait_thr = Open3.popen3("((#{command}; echo $? > tmp/exit_code) 2>&1 1>&3 | tee tmp/errorlog ) 3>&1")

      status = 'passed'
      log_complete = []
      log_error = []

      while (line = stdout.gets)
        log_complete << line
        if File.readlines('tmp/errorlog').include? line
          log_error << line
          line = line.red
          status = 'warning'
        end
        $stdout.write line
      end
    end
  rescue Timeout::Error => e
    line = "## TIMEOUT::ERROR: Command was interrupted after #{config['script_timeout']} seconds ##\n"
    log_complete << line
    log_error << line
    $stdout.write line.red
  end

  status = 'error' if File.read('tmp/exit_code').to_i != 0

  File.delete('tmp/errorlog')
  File.delete('tmp/exit_code')

  {:status => status, :log_complete => log_complete.join, :log_error => log_error.join}
end

def shell_exec_on box_name, command
  shell_exec "vagrant ssh #{box_name} -c '#{command}'"
end

def render name
  require 'erb'
  ERB.new(File.read("template/#{name}.html.erb")).result(binding)
end

result = {}

desc 'test everything on all VMs'
task :test do
  start_time = Time.now
  result[:name] = "run_#{start_time.strftime('%Y-%m-%d_%H%M%S')}"
  result[:start_time] = start_time
  result[:end_time] = ""
  unless File.directory?("tmp/of_source")
    puts '# copying openFrameworks source'
    shell_exec "cp -r #{config['of_source']} tmp/of_source"
    # saving the last commit sha
    shell_exec "cd tmp/of_source && git rev-parse HEAD > ../commit && cd -"
    # removing all the git stuff
    shell_exec "rm -rf tmp/of_source/.git"
  end
  result[:commit] = File.read('tmp/commit').chomp
  result[:systems] = []
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
    box['install_scripts'].each do |script|
      puts "# running #{script}.."
      res = shell_exec_on box['name'], "cd /vagrant/of/scripts/linux/#{box['distro']} && sudo ./#{script}"
      box_result[:tests] << {:name => script}.merge!(res)
    end

    #project generator (compile)
    puts "# compiling the project generator..."
    res = shell_exec_on box['name'], 'cd /vagrant/of/apps/devApps/projectGenerator && make -j4'
    box_result[:tests] << {:name => 'projectGenerator'}.merge!(res)

    #project generator (run --allexamples)
    puts "# running the project generator..."
    res = shell_exec_on box['name'], 'cd /vagrant/of/apps/devApps/projectGenerator/bin && ./projectGenerator --allexamples'
    box_result[:tests] << {:name => './projectGenerator --allexamples'}.merge!(res)

    #examples
    puts "## compiling all examples..."
    Dir["#{config['share_folder']}/of/examples/*/*/Makefile"].each do |makefile|
      makefile.gsub!(/^share\//, '/vagrant/')
      dir = File.dirname(makefile)
      name = dir.match /[^\/]+$/
      puts "# compiling #{name}..."
      res = shell_exec_on box['name'], "cd #{dir} && make -j4"
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

desc 'clean all temporary files'
task :clean do
  %x[rm -rf tmp/*]
  %x[rm -rf share/of]
end

def time_diff start_time, end_time
  require 'time_diff'
  d = Time.diff(start_time, end_time)
  str = []

  %w[hour minute second].each do |t|
    s = ""
    if d[t.to_sym] != 0
      s += "#{d[t.to_sym]} #{t}"
      s += "s" if d[t.to_sym] > 1
    end
    str << s if s.length > 0
  end

  str.join(' ')
end

desc 'generate web pages'
task :generate do
  require 'date'


  %x[rm -rf tmp/web]
  Dir.mkdir(config['www_dir'])
  %x[cp -R template/css tmp/web/]
  %x[cp -R template/img tmp/web/]
  %x[cp -R template/js tmp/web/]
  @results = []
  Dir["testruns/*/result.json"].each do |testrun_file|
    @results << JSON.parse(File.read(testrun_file))
  end

  @results.each do |result|
    overall = {}

    result['systems'].each do |system|
      system['tests'].each do |test|
        if overall.has_key? test['status']
          overall[test['status']] += 1
        else
          overall[test['status']] = 1
        end
      end
    end

    result['overall'] = overall
  end
  f = File.new("#{config['www_dir']}index.html", 'w+')
  f.write(render 'index')
  f.close
end
