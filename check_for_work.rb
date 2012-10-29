$:.unshift File.expand_path(File.dirname(__FILE__))

require 'json'
require 'github_api'
require 'active_record'
require 'lib/job'
ActiveRecord::Base.establish_connection(YAML.load_file('config.yml')['db'])

login = YAML.load_file('login.yml')
user  = 'openframeworks'
repo  = 'openFrameworks'

github = Github.new basic_auth: "#{login['user']}:#{login['pass']}"

#add new jobs
github.pull_requests.list(user, repo, state: 'open') do |pull_request|
  pr = github.pull_requests.get(user, repo, pull_request.number)
  if pr.mergeable
    str = "#{pr.number} - #{pr.title} - #{pr.head.repo.ssh_url} - #{pr.head.ref} - #{pr.head.sha}"
    uid = Digest::SHA1.hexdigest(str)
    unless Job.find_by_uid(uid)
      Job.create!({
        uid:       uid,
        test_type: 'pr',
        priority:  10,
        number:    pr.number,
        title:     pr.title,
        ssh_url:   pr.head.repo.ssh_url,
        branch:    pr.head.ref,
        commit:    pr.head.sha,
      })
    end
  end
end
