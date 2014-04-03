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

  describe 'Scopes' do
    describe '.for_plan_group' do
      let!(:plan_group1) { create :plan_group, name: PlanGroup::DEFAULT_NAME }
      let!(:plan_group2) { create :plan_group, name: 'foo' }
      let!(:plan_group3) { create :plan_group, name: 'bar' }
      let!(:plan1)      { create :plan }
      let!(:plan2)      { create :plan }
      let!(:plan3)      { create :plan }
      let!(:plan4)      { create :plan }
      let!(:plan5)      { create :plan }

      before do
        plan_group1.plans << plan1 << plan2 << plan3 << plan4 << plan5
        plan_group2.plans << plan2 << plan4
        plan_group3.plans << plan1 << plan5
      end

      it 'should return plans belonging to the default plan group' do
        expect(Plan.for_plan_group PlanGroup::DEFAULT_NAME).to match_array([plan1, plan2, plan3, plan4, plan5])
        expect(Plan.for_plan_group 'foo').to match_array([plan2, plan4])
        expect(Plan.for_plan_group 'bar').to match_array([plan1, plan5])
      end
    end

    describe '.for_default_plan_group' do
      let!(:plan_group) { create :plan_group, name: PlanGroup::DEFAULT_NAME }
      let!(:plan1)      { create :plan }
      let!(:plan2)      { create :plan }
      let!(:plan3)      { create :plan }

      before do
        plan_group.plans << plan1
        plan_group.plans << plan2
      end

      it 'should return plans belonging to the default plan group' do
        expect(Plan.for_default_plan_group.to_a).to match_array([plan1, plan2])
      end
    end
  end

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

  describe '#features' do
    let!(:plan) { create :plan, price: 9.99 }

    it 'should serialize features as an array' do
      plan.features = [{ 'name' => 'Custom Domains', 'live' => true }]
      plan.save
      plan.reload
      expect(plan.features).to eql([{ 'name' => 'Custom Domains', 'live' => true}])
    end
  end

  describe '#has_feature?' do
    let!(:plan) { create :plan, price: 9.99, features: [{ 'name' => 'Custom Domains', 'live' => true }] }

    it 'returns true if features has given name and is live' do
      expect(plan.has_feature?('Custom Domains')).to eq(true)
    end

    it 'returns false if features has given name but is not live' do
      plan.features.first['live'] = false
      expect(plan.has_feature?('Custom Domains')).to eq(false)
    end

    it 'returns false if features does not have given name' do
      expect(plan.has_feature?('Root Access')).to eq(false)
    end
  end

  describe '#subscriptions_count' do
    let!(:plan) { create :plan }

    before do
      create :subscription, plan: plan, state: 'active', created_at: Time.new(2014, 3, 10)
      create :subscription, plan: plan, state: 'delinquent', created_at: Time.new(2014, 3, 15)
      create :subscription, plan: plan, state: 'pending', created_at: Time.new(2014, 3, 15)

      # some edge cases to test period boundaries
      create :subscription, plan: plan, state: 'active', created_at: Time.new(2014, 2, 28)
      create :subscription, plan: plan, state: 'active', created_at: Time.new(2014, 4, 1)
      create :subscription, plan: plan, state: 'active', created_at: Time.new(2014, 3, 1, 0, 0, 0)
      create :subscription, plan: plan, state: 'active', created_at: Time.new(2014, 3, 31, 23, 59, 59)
    end

    it 'should correctly count the number of active subscriptions created within the period' do
      expect(plan.subscriptions_count(Time.new(2014, 3, 1), Time.new(2014, 3, 31))).to eq(4)
    end
  end
end
