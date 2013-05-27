require 'spec_helper'

describe Plan do
  it { should have_many(:users).through(:subscriptions) }
end
