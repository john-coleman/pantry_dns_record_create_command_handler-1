source 'https://rubygems.org'

gem 'pantry_daemon_common', git: 'git@github.com:wongatech/pantry_daemon_common.git', :tag => 'v0.1.1'

gem 'daemons'
gem 'aws-sdk'

group :development do
  gem 'guard-rspec'
  gem 'guard-bundler'
end

group :test, :development do
  gem 'em-winrm', git: 'https://github.com/pmorton/em-winrm.git', branch: 'new-eventmachine'
  gem 'simplecov', require: false
  gem 'simplecov-rcov', require: false
  gem 'rspec'
  gem 'rspec-fire'
  gem 'pry-debugger'
  gem 'rake'
end
