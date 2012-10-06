$:.unshift File.dirname(__FILE__)

require 'bundler/setup'
require 'open3'
require 'colored'
require 'json'
require 'timeout'

require 'lib/shell_exec'
require 'lib/result_utils'

@config = YAML.load_file('config.yml')
@recipes = Dir['recipes/*'].map!{|recipe| YAML.load_file(recipe)}
@result = {systems: []}

# def run_on_linux box
#   puts '# running vbguestaddition update...'
#   shell_exec "vagrant vbguest -f #{box['name']}"
# end

desc 'test everything on all VMs or specify a box by name'
task :test, :box do |t, args|
  start_time = Time.now
  @result[:name] = "run_#{start_time.strftime('%Y-%m-%d_%H%M%S')}"
  @result[:start_time] = start_time
  @result[:end_time] = ""
  unless File.directory?("tmp/of_source")
    puts '# copying openFrameworks source'
    shell_exec "cp -r #{@config['of_source']} tmp/of_source"
    # saving the last commit sha
    shell_exec "cd tmp/of_source && git rev-parse upstream/develop > ../commit && cd -"
    # removing all the git stuff
    shell_exec "rm -rf tmp/of_source/.git"
  end

  @result[:commit] = File.read('tmp/commit').chomp

  run_recipes

  puts "## generating results..."
  @result[:end_time] = Time.now
  dir_name = "testruns/#{@result[:name]}"
  Dir.mkdir(dir_name)
  File.open("#{dir_name}/result.json", 'w+', encoding: Encoding::UTF_8) {|f| f.write(JSON.pretty_generate(@result)) }
end

desc 'retest only a box or example for a given testrun'
task :retest, :testrun, :box, :example do |t, args|
  testrun = args.testrun
  box = args.box
  example = args.example
  raise "please specify an existing testrun. exit!" unless (Dir['testruns/*'].map{|d| d.gsub('testruns/','')}.include?(testrun) or testrun == 'last') and testrun
  raise "please specify an existing box. exit!" unless box
  testrun = Dir['testruns/*'].map{|d| d.gsub('testruns/','')}.sort.last if testrun == 'last'
  last_result = JSON.parse(File.read("testruns/#{testrun}/result.json"))

  #getting index of the system array in the result file
  sys_index = 0
  last_result['systems'].each{|sys| break if sys['name'] == box; sys_index += 1}

  unless example
    run_recipes box: box
    #replace it
    last_result['systems'][sys_index] = @result[:systems][0]
  else
    run_recipes box: box, example: example
    #getting index of example
    example_index = 0
    last_result['systems'][sys_index]['tests'].each{|test| break if test['name'] == example; example_index += 1}

    #getting index of new example
    new_example_index = 0
    @result[:systems][0][:tests].each{|test| break if test[:name] == example; new_example_index += 1}

    #replace it
    last_result['systems'][sys_index]['tests'][example_index] = @result[:systems][0][:tests][new_example_index]
  end

  puts "updating the result of #{testrun}..."
  File.open("testruns/#{testrun}/result.json", 'w+', encoding: Encoding::UTF_8) {|f| f.write(JSON.pretty_generate(last_result)) }
end

desc 'clean all temporary files'
task :clean do
  %x[rm -rf tmp/*]
  %x[rm -rf share/of]
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
  Dir["testruns/*/result.json"].sort.each do |testrun_file|
    @results << JSON.parse(File.read(testrun_file))
  end

  prev_overall = {}


  @results.each do |result|

    overall = {}
    result['test_names'] = []

    @commit = result['commit']

    result['bad_line_count'] = 0

    result['systems'].each do |system|
      system['bad_line_count'] = 0
      system['pretty_name'] = system['name']
      system['tests'].each do |test|
        if overall.has_key? test['status']
          overall[test['status']] += 1
        else
          overall[test['status']] = 1
        end

        result['test_names'] << test['name'] unless result['test_names'].include? test['name']

        system['bad_line_count'] += test['log_error'].count
      end
      result['bad_line_count'] += system['bad_line_count']
    end

    result['overall'] = overall
    result['prev_overall'] = prev_overall

    result_folder = "#{@testrun_folder}#{result['name']}/"
    Dir.mkdir(result_folder)

    shell_exec "tar -cjf #{result_folder}#{result['name']}.tar.bz2 testruns/#{result['name']}"

    result['complete_log_file_size'] = File.size("#{result_folder}#{result['name']}.tar.bz2") / 1024

    result['systems'].each do |system|
      sys_overall = {}
      sys_overall['passed'], sys_overall['warning'], sys_overall['error'] = 0, 0, 0
      #count results
      system['tests'].each {|test| sys_overall[test['status']] += 1}

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

    result['systems'].sort!{|a,b| a['pretty_name'] <=> b['pretty_name']}

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
  boxes = args.box ? [args.box] : @recipes.map{|b| b['box']}
  shell_exec 'mkdir -p ../vagrant_build'
  Dir.chdir '../vagrant_build'
  boxes.each do |name|
    shell_exec "rm -f #{name}.box Vagrantfile"
    shell_exec "vagrant package --base #{name} --output #{name}.box"
    shell_exec "vagrant box remove #{name}"
    shell_exec "vagrant box add #{name} #{name}.box"
  end
end

desc 'halt all running boxes with Virtualbox'
task :halt do
  puts '# halting the vm...'
  running_vm_id = shell_exec('VBoxManage list runningvms')[:log_complete][0].match(/^"(.+)"/)[1]
  shell_exec "VBoxManage controlvm #{running_vm_id} poweroff"
end

def run_recipes *args
  only_on_box = nil
  only_this_example = nil
  if args[0]
    only_on_box = args[0][:box] if args[0][:box]
    only_this_example = args[0][:example] if args[0][:example]
  end

  current_recipe = 1
  puts '## compiling on all VMs...'
  @recipes.each do |recipe|
    # if box is set through args, skip if it doesnt match
    next unless recipe['name'].match(Regexp.new(only_on_box,true)) if only_on_box

    #copying fresh of folder
    puts "# making fresh OF copy for #{recipe['name']}"
    shell_exec "rm -rf share/of"
    shell_exec "cp -r tmp/of_source share/of"

    #starting the box
    puts '# starting the vm...'
    shell_exec "vagrant up #{recipe['box']}", 120

    # #running commands from recipe
    puts "## running #{recipe['name']} as #{recipe['os'].upcase}..."
    box_result = {:name => recipe['name']}
    box_result[:tests] = []

    if recipe['os'] == 'win'
      #just trigger the net drive for the first time, dunno why, maybe bug
      puts '# waiting for the net drives on windows...'
      wait = true
      while wait do
        res = shell_exec_on recipe['box'], 'ls //vboxsvr/vagrant/'
        if res[:status] != 'error'
          wait = false
        else
          sleep 5
        end
      end
    end

    #running os specific pre commands
    puts "# running pre commands..."
    if recipe['pre_commands']
      recipe['pre_commands'].each do |where, command|
        if where == 'on_box'
          shell_exec_on recipe['box'], command
        else
          shell_exec command
        end
      end
    end

    #running install scripts
    if recipe['install_scripts']
      recipe['install_scripts'].each do |script|
        puts "# running #{script}.."
        res = shell_exec_on recipe['box'], "cd /vagrant/of/scripts/linux/#{recipe['type']} && sudo ./#{script}", 600
        box_result[:tests] << {:name => script}.merge!(res)
      end
    end

    #compile of
    %w[Debug Release].each do |target|
      puts "# compiling OF lib #{target}"
      target = target.downcase if recipe['os'] == 'win'
      res = shell_exec_on recipe['box'], recipe['lib_compile_command'].gsub('TARGET', target)
      box_result[:tests] << {:name => "OF lib #{target} compile"}.merge!(res)
    end

    #compile pg
    if recipe['pg_compile_command'] and !only_this_example
      puts "# compiling the project generator..."
      res = shell_exec_on recipe['box'], "cd /vagrant/of/apps/devApps/projectGenerator && #{recipe['pg_compile_command']}", 600
      box_result[:tests] << {:name => 'projectGenerator'}.merge!(res)
    end

    #compile examples
    puts '## compiling all examples...'
    examples = Dir["share/of/examples/*/*/Makefile"].map{|e| e =~ /android/ ? nil : e}.compact
    examples_count = examples.count
    current_example = 1
    examples.each do |makefile|
      makefile.gsub!(/^share\//, '/vagrant/')
      dir = File.dirname(makefile)
      category = File.dirname(dir).match /[^\/]+$/
      name = dir.match(/[^\/]+$/)[0]
      next unless name == only_this_example if only_this_example
      puts "# compiling #{name} ( #{current_example} / #{examples_count} ) on #{recipe['name']} ( #{current_recipe} / #{@recipes.count} )..."

      res = shell_exec_on recipe['box'], "cd #{dir} && #{recipe['examples_compile_command'].gsub('NAME', name)}", 600
      box_result[:tests] << {:name => name, :category => category}.merge!(res)

      current_example += 1
    end

    @result[:systems] << box_result

    #shutdown the vm
    puts "## shutting down the vm..."
    if recipe['os'] == 'osx'
      running_vm_id = shell_exec('VBoxManage list runningvms')[:log_complete][0].match(/^"(.+)"/)[1]
      shell_exec "VBoxManage controlvm #{running_vm_id} poweroff"
    else
      shell_exec_on recipe['box'], recipe['halt_command']
    end

    #deleting the of folder
    puts "# deleting OF folder..."
    shell_exec "rm -rf #{@config['share_folder']}/of"
    current_recipe += 1
  end
end
