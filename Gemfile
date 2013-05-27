source 'https://rubygems.org'

gem 'rails', '3.2.13'
gem 'mysql2'

# Deploy with Capistrano
gem 'capistrano'
gem 'strong_parameters'

group :development do
  gem 'thin'
end

group :test, :development do
  gem 'factory_girl_rails'
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'ci_reporter'
end
