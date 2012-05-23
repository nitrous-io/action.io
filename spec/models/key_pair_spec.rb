require 'spec_helper'

describe KeyPair do
  describe "Associations" do
    it { should belong_to :box }
  end
end
