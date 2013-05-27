require 'spec_helper'

describe Plan do
  it { should have_many(:users).through(:subscriptions) }
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }
  it { should allow_mass_assignment_of :active }
  it { should allow_mass_assignment_of :price_cents }
  it { should allow_mass_assignment_of :num_boxes }
  it { should allow_mass_assignment_of :ram }
  it { should allow_mass_assignment_of :disk_space }
  it { should allow_mass_assignment_of :ssh_access }
  it { should allow_mass_assignment_of :sleepless }

  describe '#storage' do
    it 'returns disk space in gb' do
      plan = Plan.new disk_space: 1024
      plan.storage.should eq(1)
    end
  end

  describe '#price' do
    it 'returns price in dollar' do
      plan = Plan.new price_cents: 995
      plan.price.should eq(9.95)
    end
  end
end
