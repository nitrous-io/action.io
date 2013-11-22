require 'spec_helper'

describe SubscriptionPlan do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :price }
  it { should allow_mass_assignment_of :display_order }
  it { should allow_mass_assignment_of :features }
  it { should allow_mass_assignment_of :highlight }
  it { should allow_mass_assignment_of :interval }
  it { should allow_mass_assignment_of :stripe_id }
  it { should allow_mass_assignment_of :n2o_amount }
  it { should allow_mass_assignment_of :cpu_multiplier }
  it { should allow_mass_assignment_of :vmem_multiplier }

  it { should have_many(:subscriptions) }

  describe '#has_equivalent_box_specs?' do
    let!(:free_plan) { create :subscription_plan, cpu_multiplier: 1, vmem_multiplier: 1, n2o_amount: 200 }
    let!(:free_plan_copy) { create :subscription_plan, cpu_multiplier: 1, vmem_multiplier: 1, n2o_amount: 200 }
    let!(:cheapo_plan) { create :subscription_plan, cpu_multiplier: 1, vmem_multiplier: 1, n2o_amount: 500 }
    let!(:more_cpu_plan) { create :subscription_plan, cpu_multiplier: 2, vmem_multiplier: 1, n2o_amount: 1000 }
    let!(:more_swap_plan) { create :subscription_plan, cpu_multiplier: 1, vmem_multiplier: 2, n2o_amount: 1000 }

    it 'should return true when comparing plans that have the same CPU and virtual memory multipliers' do
      expect(free_plan.has_equivalent_box_specs?(free_plan_copy)).to be_true
    end

    it 'should return true even though when plans have different n2o_amount but the same CPU and virtual memory multipliers' do
      expect(free_plan.has_equivalent_box_specs?(cheapo_plan)).to be_true
    end

    it 'should return false when comparing plans with different CPU multipliers' do
      expect(cheapo_plan.has_equivalent_box_specs?(more_cpu_plan)).to be_false
    end

    it 'should return false when comparing plans with different virtual memory multipliers' do
      expect(cheapo_plan.has_equivalent_box_specs?(more_swap_plan)).to be_false
    end
  end
end
