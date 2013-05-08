require 'rbconfig'
HOST_OS = RbConfig::CONFIG['host_os']
source 'https://rubygems.org'
ruby "1.9.3"
gem 'rails', '3.2.13'
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end
gem 'jquery-rails'
gem "pg"
gem 'jquery-ui-rails', ">= 4.0"
gem "devise", ">= 2.2.3"
gem "bootstrap-sass", "2.0.3.1"
gem "simple_form"
gem "wicked", ">= 0.4.0"
gem "geocoder"
gem "chronic", ">= 0.9.0"
gem 'backbone-on-rails', "1.0"
gem 'nestful'
gem 'dalli', ">= 2.2.1"
gem 'unicorn'
gem 'prawn', ">= 1.0.0.rc1"
gem "prawnto_2", :require => "prawnto"
gem "select2-rails"
gem 'squeel'
gem 'font-awesome-rails', ">= 3.0.2"
gem 'jbuilder'
gem 'honeybadger', ">= 1.6.2"
gem 'net-scp', "1.0.4"
gem 'fog'

group :production do
	gem 'memcachier'
	gem "sendgrid"
	gem 'newrelic_rpm', "~> 3.6.1.87"
end

group :development, :test do
	gem "rspec-rails", ">= 2.10.1"
	gem "database_cleaner", ">= 0.7.2"
	gem "email_spec", ">= 1.2.1"
	gem 'factory_girl'
	gem 'factory_girl_rails'
	gem 'quiet_assets'
	gem "bullet"
	gem 'better_errors'
	gem 'binding_of_caller'
end
