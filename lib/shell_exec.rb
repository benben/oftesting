def shell_exec command, timeout=0
  path = File.dirname(__FILE__) + '/..'
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
