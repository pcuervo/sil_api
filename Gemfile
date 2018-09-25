source 'https://rubygems.org'

ruby "2.3.1"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

#Api gems
gem 'active_model_serializers', '0.9.3'

# Used of MTI
gem 'active_record-acts_as'

gem 'rack-cors', '1.0.1'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem "paperclip", ">= 5.0"
gem 'aws-sdk', '>= 2.0.0'
gem 'aws-sdk-s3'
gem 'pg', '~> 0.20.0'
gem 'kaminari'

group :production do
  gem 'rails_12factor'
  gem 'puma'
end

gem 'web-console', '~> 2.0', group: :development

group :development, :test do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem "factory_bot_rails"
  gem 'ffaker'
  gem 'rubocop-rspec'
  gem 'byebug'
end

group :test do
  gem 'rspec-rails', '~> 3.4'
  gem 'shoulda-matchers', '~> 3.0', require: false
  gem 'database_cleaner', '~> 1.5'
end

gem "devise"
#gem 'puma'

