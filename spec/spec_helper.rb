# frozen_string_literal: true

ENV['gopher_test'] = '1'

require 'gopher2000'
require 'gopher2000/simple_client'
require 'gopher2000/rspec'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }


