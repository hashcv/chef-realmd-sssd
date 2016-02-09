require 'spec_helper'
require_relative '../serverspec/shared_serverspec_tests/joined.rb'

describe 'realmd-sssd join-realm' do
  include_examples 'joined'
end
