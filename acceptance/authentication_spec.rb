require_relative './spec_helper'
require 'pry'

describe 'Authentication' do
  it 'logs user in/out' do
    sign_in
    find('#header_view').should have_content(ENV['USERNAME'])
    sign_out
    current_path.should eq('/')
  end
end
