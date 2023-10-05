source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.1.0'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false
gem 'kaminari'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

group :development do
  gem 'rubocop'
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rspec-rails'
  gem 'webmock'
end

group :test do
  gem 'rspec_junit_formatter'
end

# lodqa
gem 'rest-client'
gem 'sparql-client'
gem 'rails_pretty_json_rednerer'
gem 'sucker_punch'

# contextualizer
gem "dotenv-rails"
gem "ruby-openai"
