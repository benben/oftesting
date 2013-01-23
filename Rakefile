$:.unshift File.dirname(__FILE__)

require 'bundler/setup'
require 'open3'
require 'colored'
require 'json'
require 'timeout'
require 'active_record'

#stuff for github
require 'github_api'
login = YAML.load_file('login.yml')
@github = Github.new basic_auth: "#{login['user']}:#{login['pass']}"

require 'lib/shell_exec'
require 'lib/result_utils'

@config = YAML.load_file('config.yml')
@recipes = Dir['recipes/*'].map!{|recipe| YAML.load_file(recipe)}
@result = {systems: []}

require 'tasks/db'

ENV['VAGRANT_HOME'] = @config['vagrant_home']

# def run_on_linux box
#   puts '# running vbguestaddition update...'
#   shell_exec "vagrant vbguest -f #{box['name']}"
# end

desc 'test everything on all VMs or specify a box by name'
task :test, :name, :box, :example do |t, args|
  start_time     = Time.now
  name           = args.name ? args.name.gsub(' ', '_') : 'standard_run'
  example        = args.example
  @result[:name] = "#{start_time.strftime('%Y%m%d_%H%M%S')}-#{name}"
  @result[:start_time] = start_time
  @result[:end_time]   = ""

  prepare_of_source!

  @result[:commit] = File.read('tmp/commit').chomp

  if args.box
    #if we want to test on all systems of a specific OS
    if args.box =~ /^os:/
      unless example
        run_recipes system: args.box.match(/^os:(.+)/)[1]
      else
        run_recipes system: args.box.match(/^os:(.+)/)[1], example: example
      end
    else
      unless example
        run_recipes box: args.box
      else
        run_recipes box: args.box, example: example
      end
    end
  else
    run_recipes
  end

  if @result[:systems].length > 0
    puts "## generating results..."
    @result[:end_time] = Time.now
    dir_name = "testruns/#{@result[:name]}"
    Dir.mkdir(dir_name)
    File.open("#{dir_name}/result.json", 'w+', encoding: Encoding::UTF_8) {|f| f.write(JSON.pretty_generate(@result)) }
  else
    puts "## exiting without generating anything, because nothing was tested (maybe box name didn't match anything)"
  end
end

desc 'open specific box with provisioned OF for inspection'
task :open, :box do |t, args|
  prepare_of_source!

  open box: args.box
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
  sys_index = -1
  last_result['systems'].each_with_index do |sys, i|
    sys_index = i if sys['name'] == box
  end

  prepare_of_source!

  #if no box matches, sys index will append to alredy existing systems
  if sys_index == -1
    sys_index = last_result['systems'].count
    last_result['systems'][sys_index] = {}
    last_result['systems'][sys_index]['name']  = ""
    last_result['systems'][sys_index]['box']   = ""
    last_result['systems'][sys_index]['tests'] = []
  end

  unless example
    run_recipes box: box
    #replace it
    unless @result[:systems][0].nil?
      last_result['systems'][sys_index]['name']  = @result[:systems][0][:name]
      last_result['systems'][sys_index]['box']   = @result[:systems][0][:box]
      last_result['systems'][sys_index]['tests'] = @result[:systems][0][:tests]
    end
  else
    run_recipes box: box, example: example
    #getting index of example
    example_index = 0
    last_result['systems'][sys_index]['tests'].each{|test| break if test['name'] == example; example_index += 1}

    #getting index of new example
    new_example_index = 0
    @result[:systems][0][:tests].each{|test| break if test[:name] == example; new_example_index += 1}

    #replace it
    if @result[:systems][0][:tests].length > 0
      last_result['systems'][sys_index]['name'] = @result[:systems][0][:name]
      last_result['systems'][sys_index]['box']  = @result[:systems][0][:box]
      last_result['systems'][sys_index]['tests'][example_index] = @result[:systems][0][:tests][new_example_index]
    end
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
  Dir["testruns/*/result.json"].each do |testrun_file|
    @results << JSON.parse(File.read(testrun_file))
  end

  @results.sort!{|a,b| a['start_time'] <=> b['start_time']}

  prev_overall = {}


  @results.each do |result|

    overall = {}
    result['test_names'] = []

    @commit = result['commit']

    result['bad_line_count'] = 0

    result['systems'].each do |system|
      system['bad_line_count'] = 0
      overall['passed'], overall['warning'], overall['error'] = 0, 0, 0
      system['tests'].each do |test|
        overall[test['status']] += 1

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

      system_folder = "#{result_folder}#{system['box']}/"
      Dir.mkdir(system_folder) unless File.directory?(system_folder)

      @asset_folder = '../'*3

      @name = result['name']
      @system = system
      f = File.new("#{system_folder}index.html", 'w+')
      f.write(render 'system')
      f.close

      Dir.mkdir("#{system_folder}tests") unless File.directory?("#{system_folder}tests")

      @asset_folder = '../'*5
      system['tests'].each do |test|
        @test = test
        test_folder = "#{system_folder}tests/#{test['name']}/"
        Dir.mkdir(test_folder) unless File.directory?(test_folder)
        f = File.new("#{test_folder}index.html", 'w+')
        f.write(render 'test')
        f.close
      end
    end

    result['systems'].sort!{|a,b| a['name'] <=> b['name']}

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
  running_vm_ids = shell_exec('VBoxManage list runningvms')[:log_complete].map{|line| line.match(/^"(.+)"/)[1]}

  running_vm_ids.each do |vm_id|
    puts "# halting #{vm_id}..."
    shell_exec "VBoxManage controlvm #{vm_id} poweroff"
  end
end

def open *args
  only_on_box = nil
  if args[0]
    only_on_box = args[0][:box] if args[0][:box]
  end

  if only_on_box
    @recipes.each do |recipe|
      next unless recipe['name'].match(Regexp.new(only_on_box,true))

      copy_of_source!

      patch_of_source!

      #patch gui mode in Vagrantfile for this moment
      content = File.read('Vagrantfile')
      replace = content.gsub(/#box_config.vm.boot_mode = :gui/, 'box_config.vm.boot_mode = :gui')
      File.open('Vagrantfile', 'w') {|file| file.puts replace}

      #starting the box
      puts '# starting the vm...'
      shell_exec "vagrant up #{recipe['box']}", 120

      #revert changes...
      content = File.read('Vagrantfile')
      replace = content.gsub(/box_config.vm.boot_mode = :gui/, '#box_config.vm.boot_mode = :gui')
      File.open('Vagrantfile', 'w') {|file| file.puts replace}

      # #running commands from recipe
      puts "## running #{recipe['name']} as #{recipe['os'].upcase}..."

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

      #break sicne we wnat to run it only on one box
      break
    end
  end
end

def run_recipes *args
  only_on_box = nil
  only_this_example = nil
  if args[0]
    only_on_box       = args[0][:box]     if args[0][:box]
    only_this_example = args[0][:example] if args[0][:example]
    only_on_system    = args[0][:system]  if args[0][:system]
  end

  current_recipe = 1
  puts '## compiling on all VMs...'
  @recipes.each do |recipe|
    # if box is set through args, skip if it doesnt match
    next unless recipe['name'].match(Regexp.new(only_on_box,true)) if only_on_box
    next unless recipe['os'].match(Regexp.new(only_on_system,true)) if only_on_system

    copy_of_source!

    patch_of_source!

    #starting the box
    puts '# starting the vm...'
    shell_exec "vagrant up #{recipe['box']}", 120

    # #running commands from recipe
    puts "## running #{recipe['name']} as #{recipe['os'].upcase}..."
    box_result = {:name => recipe['name'], :box => recipe['box']}
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
      box_result[:tests] << {:name => "OF lib #{target.capitalize} compile"}.merge!(res)
    end

    #compile pg
    if recipe['pg_compile_command'] and !only_this_example
      puts "# compiling the project generator..."
      res = shell_exec_on recipe['box'], "cd /vagrant/of/apps/devApps/projectGenerator && #{recipe['pg_compile_command']}", 600
      box_result[:tests] << {:name => 'projectGenerator'}.merge!(res)
    end

    #compile examples
    puts '## compiling all examples...'
    examples = Dir["share/of/examples/*/*/Makefile"].delete_if{|e| e =~ /android/}
    #remove osx examples if we're not on osx
    examples = examples.delete_if{|e| e =~ /osx/} unless recipe['os'] == 'osx'
    examples_count = only_this_example ? 1 : examples.count
    current_example = 1
    examples.each do |makefile|
      makefile.gsub!(/^share\//, '/vagrant/')
      dir = File.dirname(makefile)
      category = File.dirname(dir).match /[^\/]+$/
      name = dir.match(/[^\/]+$/)[0]
      next unless name == only_this_example if only_this_example
      recipe_count = only_on_box ? 1 : @recipes.count
      puts "# compiling #{name} ( #{current_example} / #{examples_count} ) on #{recipe['name']} ( #{current_recipe} / #{recipe_count} )..."

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

    #kill all remaining running vms
    Rake::Task["halt"].execute

    #deleting the of folder
    puts "# deleting OF folder..."
    shell_exec "rm -rf #{@config['share_folder']}/of"
    current_recipe += 1
  end
end

def prepare_of_source!
  unless File.directory?("tmp/of_source")
    puts '# copying openFrameworks source'
    shell_exec "cp -r #{@config['of_source']} tmp/of_source"
    # saving the last commit sha
    shell_exec "cd tmp/of_source && git rev-parse develop > ../commit && cd -"
    # removing all the git stuff
    shell_exec "rm -rf tmp/of_source/.git"
  end
end

def copy_of_source!
  #copying fresh of folder
  puts "# making fresh temp OF copy"
  shell_exec "rm -rf share/of"
  shell_exec "cp -r tmp/of_source share/of"
end

def patch_of_source!
  puts "## patching OF source for automation..."
  Dir["share/of/scripts/linux/{debian,ubuntu}/*"].each do |f|
    content = File.read(f)
    replace = content.gsub(/apt-get/, 'apt-get -y --force-yes')
    File.open(f, "w") {|file| file.puts replace}
  end

  Dir["share/of/scripts/linux/fedora/*"].each do |f|
    content = File.read(f)
    replace = content.gsub(/yum/, 'yum -y')
    File.open(f, "w") {|file| file.puts replace}
  end

  Dir["share/of/scripts/linux/archlinux/*"].each do |f|
    content = File.read(f)
    replace = content.gsub(/pacman -Sy --needed/, 'pacman -Sy --noprogressbar --needed --noconfirm')
    replace = replace.gsub(/pacman -Rs/, 'pacman -Rs --noconfirm')
    File.open(f, "w") {|file| file.puts replace}
  end

  %w(share/of/scripts/linux/compileOF.sh share/of/scripts/linux/compilePG.sh).each do |f|
    content = File.read(f)
    replace = content.gsub(/make Debug/, 'make -j4 Debug')
    replace = replace.gsub(/make Release/, 'make -j4 Release')
    File.open(f, "w") {|file| file.puts replace}
  end
end

desc "Update openframeworks source in #{@config['of_source']}"
task :update_source do
  Dir.chdir(@config['of_source']) do
    puts `git fetch upstream`
    puts `git checkout master`
    puts `git merge upstream/master`
    puts `git push origin master`
    puts `git checkout develop`
    puts `git merge upstream/develop`
    puts `git push origin develop`
  end
end

desc "Add a PR branch to the openframeworks source in #{@config['of_source']}"
task :prepare_pr, :pull_request_id do |t, args|
  unless args.pull_request_id
    puts "please specify a pull_request_id"
    exit
  end
  pull_request_id = args.pull_request_id

  pr = @github.pull_requests.get('openframeworks', 'openFrameworks', pull_request_id)

  unless pr.mergeable
    puts "this PR cannot be merged automatically."
    exit
  end

  owner   = pr.head.repo.owner.login
  git_url = pr.head.repo.git_url
  branch  = pr.head.ref

  Dir.chdir(@config['of_source']) do
    unless `git remote`.split("\n").include?(owner)
      puts "# adding remote '#{owner}' to of source"
      puts `git remote add #{owner} #{git_url}`
    end
    pr_branch_name = "pr_#{pull_request_id}"
    puts `git fetch #{owner} #{branch}:#{pr_branch_name}`
    puts `git checkout develop`
    #TODO: if branch exists, checkout only
    puts `git checkout -b develop_merged_with_#{pr_branch_name}`
    puts `git merge #{pr_branch_name}`
  end
end
