source 'https://rubygems.org'

gem 'rails', '3.2.13'
gem 'rspec'
gem 'mysql2'
gem 'delayed_job_active_record'
gem 'omniauth-ldap'

gem 'strong_parameters'
gem 'haml-rails'
gem 'chef'
gem 'em-winrm'
gem 'daemons'

group :development do
  gem 'thin'
  gem 'guard-rspec'
  gem 'guard-cucumber'
end

group :test, :development do
  gem 'chef-zero'
  gem 'guard-cucumber'
  gem 'guard-rspec'
  gem 'factory_girl_rails'
  gem 'pry-rails'
  gem 'rspec-rails', '> 2.14.rc1'
  gem 'pry-debugger'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'ci_reporter'
  gem 'timecop'
end
