require 'spec_helper'

describe AddonCategory do
  it { should have_many(:addons) }
end
