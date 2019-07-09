source 'https://rubygems.org'

gem 'rake', "< 11.0"
gem 'multi_json',  '~> 1.2'

if RUBY_PLATFORM != "java"
  gem 'coveralls', :require => false
  gem 'simplecov', :require => false
end
gem 'rest-client', '1.6.7'

platforms :ruby do
  gem 'mongov1',     '~> 1.9', git: 'https://github.com/dressipi/mongo-ruby-driver.git', branch: 'rename-legacy-mongo'
  gem 'bsonv1_ext',  '~> 1.9', git: 'https://github.com/dressipi/mongo-ruby-driver.git', branch: 'rename-legacy-mongo'
end

gem 'plucky', git:  'https://github.com/fcheung/plucky.git', branch: 'use-legacy-mongo'
platforms :rbx do
  gem "rubysl"
end

group :test do
  gem 'test-unit',      '~> 3.0'
  gem 'rspec',          '~> 3.1.0'
  gem 'timecop',        '= 0.6.1'
  gem 'rack-test',      '~> 0.5'
  gem 'generator_spec', '~> 0.9'

  platforms :mri_18 do
    gem 'ruby-debug'
  end

  platforms :mri_19 do
    gem 'debugger'
  end

  platforms :mri_20 do
    gem 'pry'
  end
end
