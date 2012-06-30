require 'bundler/setup'
require 'open3'
require 'colored'
require 'json'
require 'timeout'

@config = YAML.load_file('config.yml')

def shell_exec command, timeout=0
  path = File.dirname(__FILE__)
  status = 'passed'
  log_complete = []
  log_error = []

  begin
    Timeout::timeout(timeout) do
      # running the command, writing exit code to tmp/exit_code, writing all errors to tmp/errorlog, piping everything to stdout
      stdin, stdout, stderr, wait_thr = Open3.popen3("((#{command}; echo $? > #{path}/tmp/exit_code) 2>&1 1>&3 | tee #{path}/tmp/errorlog ) 3>&1")

      while (line = stdout.gets)
        log_complete << line
        if File.exists?("#{path}/tmp/errorlog")
          if File.readlines("#{path}/tmp/errorlog").include? line
            log_error << line
            line = line.red
            status = 'warning'
          end
        end
        $stdout.write line
      end

      status = 'error' if File.read("#{path}/tmp/exit_code").to_i != 0
    end
  rescue Timeout::Error => e
    line = "## TIMEOUT::ERROR: Command was interrupted after #{timeout} seconds ##\n"
    log_complete << line
    log_error << line
    status = 'error'
    $stdout.write line.red
  end

  %x[rm -f #{path}/tmp/errorlog]
  %x[rm -f #{path}/tmp/exit_code]

  {:status => status, :log_complete => log_complete, :log_error => log_error}
end

def shell_exec_on box_name, command, timeout=0
  shell_exec "vagrant ssh #{box_name} -c '#{command}'", timeout
end

def render name
  require 'erb'
  ERB.new(File.read("template/#{name}.html.erb")).result(binding)
end

@result = {}
@result[:systems] = []

def run_on_linux box
  box_result = {:name => box['name']}
  box_result[:tests] = []
  puts "# running pre command..."
  shell_exec_on box['name'], "#{box['pre_command']}"

  #install scripts
  box['install_scripts'].each do |script|
    puts "# running #{script}.."
    res = shell_exec_on box['name'], "cd /vagrant/of/scripts/linux/#{box['distro']} && sudo ./#{script}", 600
    box_result[:tests] << {:name => script}.merge!(res)
  end

  #compiling OF lib Debug and Release
  %w[Debug Release].each do |target|
    puts "# compiling OF lib #{target}"
    bit = box['name'].match(/(64)bit$/) ? '64' : ''
    res = shell_exec_on box['name'], "cd /vagrant/of/libs/openFrameworksCompiled/project/linux#{bit}/ && make clean ; make -j4 #{target}"
    box_result[:tests] << {:name => "OF lib #{target} compile"}.merge!(res)
  end

  #project generator (compile)
  puts "# compiling the project generator..."
  res = shell_exec_on box['name'], 'cd /vagrant/of/apps/devApps/projectGenerator && make clean ; make -j4'
  box_result[:tests] << {:name => 'projectGenerator'}.merge!(res)

  # #project generator (run --allexamples)
  # puts "# running the project generator..."
  # res = shell_exec_on box['name'], 'cd /vagrant/of/apps/devApps/projectGenerator/bin && ./projectGenerator --allexamples', 120
  # box_result[:tests] << {:name => './projectGenerator --allexamples'}.merge!(res)

  #examples
  puts "## compiling all examples..."
  Dir["#{@config['share_folder']}/of/examples/*/*/Makefile"].each do |makefile|
    makefile.gsub!(/^share\//, '/vagrant/')
    dir = File.dirname(makefile)
    name = dir.match /[^\/]+$/
    puts "# compiling #{name}..."
    res = shell_exec_on box['name'], "cd #{dir} && make -j4"
    box_result[:tests] << {:name => name}.merge!(res)
  end

  @result[:systems] << box_result

  puts '# running vbguestaddition update...'
  shell_exec "vagrant vbguest -f #{box['name']}"

  puts '# halting the vm...'
  shell_exec "vagrant halt #{box['name']}"
end

def run_on_osx box
  box_result = {:name => box['name']}
  box_result[:tests] = []

  puts '# copying OF via scp...'
  shell_exec_on box['name'], 'rm -rf /vagrant/of'
  shell_exec "scp -P 2222 -i vagrant_private_key -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no #{@config['share_folder']}of/ vagrant@localhost:/vagrant/of"

  #compiling OF lib
  puts "# compiling OF lib"
  res = shell_exec_on box['name'], "cd /vagrant/of/libs/openFrameworksCompiled/project/osx/ && xcodebuild -alltargets -parallelizeTargets", 600
  box_result[:tests] << {:name => "OF lib compile"}.merge!(res)

  #project generator (compile)
  puts "# compiling the project generator..."
  res = shell_exec_on box['name'], 'cd /vagrant/of/apps/devApps/projectGenerator && xcodebuild -alltargets -parallelizeTargets', 600
  box_result[:tests] << {:name => 'projectGenerator'}.merge!(res)

  #examples
  puts '## compiling all examples...'
  Dir["#{@config['share_folder']}of/examples/*/*/Makefile"].each do |makefile|
    makefile.gsub!(/^share\//, '/vagrant/')
    dir = File.dirname(makefile)
    name = dir.match /[^\/]+$/
    puts "# compiling #{name}..."
    res = shell_exec_on box['name'], "cd #{dir} && xcodebuild -alltargets -parallelizeTargets", 600
    box_result[:tests] << {:name => name}.merge!(res)
  end

  @result[:systems] << box_result

  puts '# halting the vm...'
  running_vm_id = shell_exec('VBoxManage list runningvms')[:log_complete][0].match(/^"(.+)"/)[1]
  shell_exec "VBoxManage controlvm #{running_vm_id} poweroff"
end

desc 'test everything on all VMs'
task :test do
  start_time = Time.now
  @result[:name] = "run_#{start_time.strftime('%Y-%m-%d_%H%M%S')}"
  @result[:start_time] = start_time
  @result[:end_time] = ""
  unless File.directory?("tmp/of_source")
    puts '# copying openFrameworks source'
    shell_exec "cp -r #{@config['of_source']} tmp/of_source"
    # saving the last commit sha
    shell_exec "cd tmp/of_source && git rev-parse HEAD > ../commit && cd -"
    # removing all the git stuff
    shell_exec "rm -rf tmp/of_source/.git"
  end

  @result[:commit] = File.read('tmp/commit').chomp

  puts '## compiling on all VMs...'
  @config['boxes'].each do |box|
    puts "# making fresh OF copy for #{box['name']}"
    shell_exec "rm -rf #{@config['share_folder']}of"
    shell_exec "cp -r tmp/of_source #{@config['share_folder']}of"
    puts '# starting the vm...'
    shell_exec "vagrant up #{box['name']}"

    if box['distro'] =~ /osx/
      run_on_osx box
    elsif box['distro'] =~ /win/
      puts "run on win is a stub"
    else
      run_on_linux box
    end
    puts "# deleting OF folder..."
    shell_exec "rm -rf #{@config['share_folder']}/of"
  end

  puts "## generating results..."
  @result[:end_time] = Time.now
  dir_name = "testruns/#{@result[:name]}"
  Dir.mkdir(dir_name)
  File.open("#{dir_name}/result.json", 'w+', encoding: Encoding::UTF_8) {|f| f.write(JSON.pretty_generate(@result)) }
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
  Dir.mkdir(@config['www_dir'])
  @testrun_folder = "#{@config['www_dir']}testruns/"
  Dir.mkdir(@testrun_folder)
  %x[cp -R template/css tmp/web/]
  %x[cp -R template/img tmp/web/]
  %x[cp -R template/js tmp/web/]
  @results = []
  Dir["testruns/*/result.json"].reverse.each do |testrun_file|
    @results << JSON.parse(File.read(testrun_file))
  end

  prev_overall = {}

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
    result['prev_overall'] = prev_overall

    result_folder = "#{@testrun_folder}#{result['name']}/"
    Dir.mkdir(result_folder)

    shell_exec "tar -cjf #{result_folder}#{result['name']}.tar.bz2 testruns/#{result['name']}"

    result['complete_log_file_size'] = File.size("#{result_folder}#{result['name']}.tar.bz2") / 1024

    result['systems'].each do |system|
      sys_overall = {}

      system['tests'].each do |test|
        if sys_overall.has_key? test['status']
          sys_overall[test['status']] += 1
        else
          sys_overall[test['status']] = 1
        end
      end

      system['overall'] = sys_overall

      system_folder = "#{result_folder}#{system['name']}/"
      Dir.mkdir(system_folder)

      @asset_folder = '../'*3

      @name = result['name']
      @system = system
      f = File.new("#{system_folder}index.html", 'w+')
      f.write(render 'system')
      f.close

      Dir.mkdir("#{system_folder}tests")

      @asset_folder = '../'*5
      system['tests'].each do |test|
        @test = test
        test_folder = "#{system_folder}tests/#{test['name']}/"
        Dir.mkdir(test_folder)
        f = File.new("#{test_folder}index.html", 'w+')
        f.write(render 'test')
        f.close
      end
    end

    @result = result
    @asset_folder = '../'*2

    f = File.new("#{result_folder}index.html", 'w+')
    f.write(render 'result')
    f.close

    prev_overall = overall
  end

  @asset_folder = ''
  f = File.new("#{@config['www_dir']}index.html", 'w+')
  f.write(render 'index')
  f.close
end

desc 'deploy to github pages'
task :deploy do
  Dir.chdir '../'
  if File.exists?('web_deploy/')
    Dir.chdir 'web_deploy/'
    shell_exec 'git checkout gh-pages'
    shell_exec 'git pull origin gh-pages'
    Dir.chdir '../'
  else
    shell_exec 'git clone git@github.com:benben/oftesting.git web_deploy'
    Dir.chdir 'web_deploy/'
    shell_exec 'git checkout gh-pages'
    Dir.chdir '../'
  end
  shell_exec 'cp -R oftesting/tmp/web/* web_deploy/'
  Dir.chdir 'web_deploy/'
  shell_exec 'git add .'
  shell_exec "git commit -am 'Deploy from #{Time.now}'"
  shell_exec 'git push origin gh-pages'
end

desc 'create all vagrant boxes or specify one box'
task :create, :box do |t, args|
  boxes = args.box ? [args.box] : @config['boxes'].map{|b| b['name']}
  shell_exec 'mkdir -p ../vagrant_build'
  Dir.chdir '../vagrant_build'
  boxes.each do |name|
    shell_exec "rm -f #{name}.box Vagrantfile"
    shell_exec "vagrant package --base #{name} --output #{name}.box"
    shell_exec "vagrant box remove #{name}"
    shell_exec "vagrant box add #{name} #{name}.box"
  end
end
