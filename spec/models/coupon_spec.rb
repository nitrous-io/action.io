require 'spec_helper'

describe Coupon do
  it { should have_many :subscriptions }
end
