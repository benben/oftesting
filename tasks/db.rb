namespace :db do
  desc "create the database"
  task :create do
    if File.exist?(@config['db']['database'])
      $stderr.puts "#{@config['db']['database']} already exists"
    else
      begin
        ActiveRecord::Base.establish_connection(@config['db'])
        ActiveRecord::Base.connection
      rescue Exception => e
        $stderr.puts e, *(e.backtrace)
        $stderr.puts "Couldn't create database for #{@config['db'].inspect}"
      end
    end
  end

  desc "migrate the database"
  task :migrate do
    unless File.exist?(@config['db']['database'])
      Rake::Task['db:create'].execute
    else
      ActiveRecord::Base.establish_connection(@config['db'])
      ActiveRecord::Migrator.migrate('lib/db', nil)
    end
  end

  desc 'drop the database'
  task :drop do
    begin
      FileUtils.rm(@config['db']['database'])
    rescue Exception => e
      $stderr.puts "Couldn't drop #{@config['db']['database']} : #{e.inspect}"
    end
  end

  desc 'Resets your database using your migrations for the current environment (drop -> create -> migrate)'
  task :reset => ["db:drop", "db:create", "db:migrate"]
end
