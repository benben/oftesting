$:.unshift File.expand_path(File.dirname(__FILE__))

require 'json'
require 'github_api'
require 'active_record'
ActiveRecord::Base.establish_connection(YAML.load_file('config.yml')['db'])

login = YAML.load_file('login.yml')
user  = 'openframeworks'
repo  = 'openFrameworks'

github = Github.new basic_auth: "#{login['user']}:#{login['pass']}"

#get latest sha's from open PR's

pull_requests = []

github.pull_requests.list(user, repo, state: 'open') do |pr|
  temp = github.pull_requests.get(user, repo, pr.number)
  pull_requests << temp if temp.mergeable
end


require 'pry'
binding.pry
