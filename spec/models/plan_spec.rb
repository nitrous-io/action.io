require 'spec_helper'

describe Plan do
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
  it { should allow_mass_assignment_of :memory }
  it { should allow_mass_assignment_of :storage }

  it { should have_many(:subscriptions) }
  it { should have_many(:plan_group_memberships) }

  describe '#is_spec_downgrade_from' do
    let!(:free_plan)      { create :plan, cpu_multiplier: 1, vmem_multiplier: 1, n2o_amount: 200 }
    let!(:free_plan_copy) { create :plan, cpu_multiplier: 1, vmem_multiplier: 1, n2o_amount: 200 }
    let!(:cheapo_plan)    { create :plan, cpu_multiplier: 1, vmem_multiplier: 1, n2o_amount: 500 }
    let!(:more_cpu_plan)  { create :plan, cpu_multiplier: 2, vmem_multiplier: 1, n2o_amount: 1000 }
    let!(:more_swap_plan) { create :plan, cpu_multiplier: 1, vmem_multiplier: 2, n2o_amount: 1000 }

    it 'should return false when comparing plans that have the same CPU and virtual memory multipliers' do
      expect(free_plan.is_spec_downgrade_from(free_plan_copy)).to be_falsey
    end

    it 'should return false even though when plans have different n2o_amount but the same CPU and virtual memory multipliers' do
      expect(free_plan.is_spec_downgrade_from(cheapo_plan)).to be_falsey
    end

    it 'should return true when other plan has a higher CPU multiplier' do
      expect(cheapo_plan.is_spec_downgrade_from(more_cpu_plan)).to be_truthy
    end

    it 'should return true when other plan has a virtual memory multiplier' do
      expect(cheapo_plan.is_spec_downgrade_from(more_swap_plan)).to be_truthy
    end
  end

  describe '#is_price_downgrade_from' do
    let!(:free_plan)         { create :plan, price: 0.00 }
    let!(:cheapo_plan)       { create :plan, price: 9.99 }
    let!(:cheapo_plan_copy)  { create :plan, price: 9.99 }
    let!(:eduardo_plan)      { create :plan, price: 999.99 }

    it 'should return false when comparing plans that have the same price' do
      expect(cheapo_plan.is_price_downgrade_from(cheapo_plan_copy)).to be_falsey
    end

    it 'should return true when other plan has a higher price' do
      expect(free_plan.is_price_downgrade_from(cheapo_plan)).to be_truthy
    end

    it 'should return false when other plan has a lower price' do
      expect(eduardo_plan.is_price_downgrade_from(cheapo_plan)).to be_falsey
    end
  end

  describe "#price_as_currcency" do
    let!(:start) { create :plan, price: 9.99 }
    let!(:shift) { create :plan, price: 19.99 }
    let!(:turbo) { create :plan, price: 39.99 }
    let!(:nitro) { create :plan, price: 79.99 }

    it 'precents the price with currency symobol and value formatted to 2 decimal places' do
      expect(start.price_as_currency).to eq 'USD 9.99'
      expect(shift.price_as_currency).to eq 'USD 19.99'
      expect(turbo.price_as_currency).to eq 'USD 39.99'
      expect(nitro.price_as_currency).to eq 'USD 79.99'
    end
  end

  describe "#price_in_cents" do
    let!(:start) { create :plan, price: 9.99 }
    let!(:shift) { create :plan, price: 19.99 }
    let!(:turbo) { create :plan, price: 39.99 }
    let!(:nitro) { create :plan, price: 79.99 }

    it 'converts the value to cents' do
      expect(start.price_in_cents).to eq 999
      expect(shift.price_in_cents).to eq 1999
      expect(turbo.price_in_cents).to eq 3999
      expect(nitro.price_in_cents).to eq 7999
    end
  end
end
