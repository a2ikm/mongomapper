source 'https://rubygems.org'

gem 'bson', '4.8.2'

gem 'rake', "< 11.0"
gem 'multi_json',  '~> 1.2'

gem 'plucky', git: "https://github.com/fcheung/plucky.git", branch: 'mongo-2.x'

if RUBY_PLATFORM != "java"
  gem 'coveralls', '~> 0.8.0', :require => false
  gem 'simplecov', :require => false
end
gem 'rest-client', '1.6.7'

platforms :ruby do
  gem 'mongo',     '~> 2.0'
end

platforms :rbx do
  gem "rubysl"
end

group :test do
  gem 'test-unit',      '~> 3.0'
  gem 'rspec',          '~> 3.4.0'
  gem 'timecop',        '= 0.6.1'
  gem 'rack-test',      '~> 0.5'
  gem 'generator_spec', '~> 0.9'
  gem 'byebug'
end
