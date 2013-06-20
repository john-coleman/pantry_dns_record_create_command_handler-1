source 'https://rubygems.org'

gem 'rails', '3.2.13'
gem 'mysql2'

gem 'strong_parameters'
gem 'haml-rails'
gem 'chef'
gem 'em-winrm'

group :development do
  gem 'thin'
end

group :test, :development do
  gem 'chef-zero'
  gem 'factory_girl_rails'
  gem 'pry-rails'
  gem 'rspec-rails', '> 2.14.rc1'
  gem 'pry-debugger'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'ci_reporter'
  gem 'timecop'
end
