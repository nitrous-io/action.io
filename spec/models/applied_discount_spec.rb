require 'spec_helper'

describe AppliedDiscount do
  it { should allow_mass_assignment_of :percent_off }
  it { should allow_mass_assignment_of :amount_off }
  it { should allow_mass_assignment_of :stripe_customer_id }
  it { should allow_mass_assignment_of :started_at }
  it { should allow_mass_assignment_of :ended_at }

  describe '.active_in_period' do
    let!(:discount1) { create :applied_discount, started_at: Time.new(2014, 3, 1, 00, 00, 00).utc, ended_at: Time.new(2014, 4, 1, 00, 00, 00).utc }
    let!(:discount2) { create :applied_discount, started_at: Time.new(2014, 4, 1, 00, 00, 00).utc, ended_at: Time.new(2014, 6, 1, 00, 00, 00).utc }
    let!(:discount3) { create :applied_discount, started_at: Time.new(2014, 2, 1, 00, 00, 00).utc, ended_at: Time.new(2014, 3, 1, 00, 00, 00).utc }
    let!(:discount4) { create :applied_discount, started_at: Time.new(2014, 2, 1, 00, 00, 00).utc, ended_at: Time.new(2014, 2, 28, 00, 00, 00).utc }
    let!(:discount5) { create :applied_discount, started_at: Time.new(2014, 3, 15, 00, 00, 00).utc, ended_at: Time.new(2014, 3, 25, 00, 00, 00).utc }

    it 'should not include discounts scheduled to start after or ended before the given period' do
      period_start = Time.new(2014, 3, 1, 00, 00, 00).utc
      period_end = Time.new(2014, 3, 31, 23, 59, 59).utc

      expect(AppliedDiscount.active_in_period(period_start, period_end).to_a).to match_array([discount1, discount5])
    end

    it 'should include discounts starts and ends within the given period' do
      period_start = Time.new(2014, 3, 1, 00, 00, 00).utc
      period_end = Time.new(2014, 3, 31, 23, 59, 59).utc

      expect(AppliedDiscount.active_in_period(period_start, period_end).to_a).to include(discount5)
    end
  end

  describe '.data_for_period' do
    let!(:plan1) { create :plan, stripe_id: "plan1", price: 5.00 }

    let!(:discount1) { create :applied_discount, stripe_customer_id: "cus_001", percent_off: 10, started_at: Time.new(2014, 3, 10, 00, 00, 00).utc, ended_at: Time.new(2014, 5, 10, 00, 00, 00).utc }
    let!(:discount2) { create :applied_discount, stripe_customer_id: "cus_002", percent_off: 10, started_at: Time.new(2014, 3, 10, 00, 00, 00).utc, ended_at: Time.new(2014, 5, 10, 00, 00, 00).utc }
    let!(:discount3) { create :applied_discount, stripe_customer_id: "cus_003", percent_off: 10, started_at: Time.new(2014, 3, 10, 00, 00, 00).utc, ended_at: Time.new(2014, 5, 10, 00, 00, 00).utc }

    let!(:revenue_event_1) { create :revenue_event, stripe_customer_id: "cus_001", stripe_plan_id: "plan1", event: RevenueEvent::SUBSCRIBED, created_at: Time.new(2014, 3, 10).utc }
    let!(:revenue_event_2) { create :revenue_event, stripe_customer_id: "cus_002", stripe_plan_id: "plan1", event: RevenueEvent::UPGRADED, created_at: Time.new(2014, 3, 15).utc }
    let!(:revenue_event_3) { create :revenue_event, stripe_customer_id: "cus_003", stripe_plan_id: "plan1", event: RevenueEvent::CANCELED, created_at: Time.new(2014, 3, 25).utc }

    it 'should calculate the amount and count correctly' do
      expect(AppliedDiscount.data_for_period(Time.new(2014, 3, 1), Time.new(2014, 3, 31))).to eq({ amount: 100, count: 2 })
    end

    context 'when period is over one month' do
      it 'should calculate the amount considering calendar months in given period' do
        expect(AppliedDiscount.data_for_period(Time.new(2014, 3, 1), Time.new(2014, 4, 30))).to eq({ amount: 200, count: 2 })
      end
    end
  end
end
