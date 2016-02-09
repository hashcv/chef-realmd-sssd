require 'serverspec'

set :backend, :exec

require_relative '../serverspec/shared_serverspec_tests/default.rb'

describe 'realmd-sssd default' do
  include_examples 'default'
end
