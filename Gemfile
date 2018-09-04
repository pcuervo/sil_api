source 'https://rubygems.org'

#ruby "2.2"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'
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
gem 'active_record-acts_as', '1.0.7'

gem 'rack-cors', :require => 'rack/cors'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem "paperclip", "~> 4.3"
gem 'aws-sdk', '< 2.0'
gem "pg", "< 1.0"
gem 'kaminari'

group :production do
  gem 'rails_12factor'
  gem 'puma'
end

group :development, :test do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'factory_girl_rails', '4.5.0'
  gem 'ffaker'
  #gem 'byebug'
end

group :test do
  #gem "rspec-rails", "~> 2.14"
  gem 'rspec-rails', '~> 3.1'
  gem "shoulda-matchers"
end

gem "devise"
#gem 'puma'

