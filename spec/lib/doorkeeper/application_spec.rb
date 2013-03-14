require 'spec_helper'

describe Doorkeeper::Application do
  describe 'validations' do
    before { create :doorkeeper_application }
    it { should validate_uniqueness_of :name }
  end
end
