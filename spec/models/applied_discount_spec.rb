require 'spec_helper'

describe AppliedDiscount do
  it { should allow_mass_assignment_of :percent_off }
  it { should allow_mass_assignment_of :amount_off }
  it { should allow_mass_assignment_of :stripe_customer_id }
  it { should allow_mass_assignment_of :stripe_event_id }
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
  end

  describe '.discounted_value_as_of' do
    let!(:plan1) { create :plan, stripe_id: "plan1", price: 5.00 }
    let!(:plan2) { create :plan, stripe_id: "plan2", price: 10.00 }

    let!(:revenue_event_subscribed) { create :revenue_event, stripe_customer_id: "cus_001", amount: 500, stripe_plan_id: "plan1", event: RevenueEvent::SUBSCRIBED, created_at: Time.new(2014, 3, 9).utc }
    let!(:revenue_event_upgraded) { create :revenue_event, stripe_customer_id: "cus_001", amount: 500, stripe_plan_id: "plan2", event: RevenueEvent::UPGRADED, created_at: Time.new(2014, 3, 10).utc }
    let!(:revenue_event_canceled) { create :revenue_event, stripe_customer_id: "cus_002", amount: 500, stripe_plan_id: "plan1", event: RevenueEvent::CANCELED, created_at: Time.new(2014, 2, 10).utc }

    let!(:active_discount) { create :applied_discount, stripe_customer_id: "cus_001", percent_off: 10, started_at: Time.new(2014, 3, 10, 00, 00, 00).utc, ended_at: Time.new(2014, 3, 15, 00, 00, 00).utc }
    let!(:active_discount_with_canceled_subscription) { create :applied_discount, stripe_customer_id: "cus_002", percent_off: 10, started_at: Time.new(2014, 2, 10, 00, 00, 00).utc, ended_at: Time.new(2014, 3, 15, 00, 00, 00).utc }

    let!(:expired_discount) { create :applied_discount, stripe_customer_id: "cus_001", percent_off: 10, started_at: Time.new(2014, 3, 1, 00, 00, 00).utc, ended_at: Time.new(2014, 3, 9, 00, 00, 00).utc }
    let!(:pending_discount) { create :applied_discount, stripe_customer_id: "cus_001", percent_off: 10, started_at: Time.new(2014, 3, 12, 00, 00, 00).utc, ended_at: Time.new(2014, 3, 15, 00, 00, 00).utc }

    it 'should calculate the amount and count correctly' do
      expect(AppliedDiscount.discounted_value_as_of(Time.new(2014, 3, 11))).to eq({ amount: 100, count: 1 })
    end
  end

  describe '.data_for_period' do
    let!(:plan1) { create :plan, stripe_id: "plan1", price: 5.00 }
    let!(:plan2) { create :plan, stripe_id: "plan2", price: 10.00 }

    let!(:revenue_event_subscribed) { create :revenue_event, stripe_customer_id: "cus_001", amount: 500, stripe_plan_id: "plan1", event: RevenueEvent::SUBSCRIBED, created_at: Time.new(2014, 3, 9).utc }
    let!(:discount_for_subscription) { create :applied_discount, stripe_customer_id: "cus_001", percent_off: 10, started_at: Time.new(2014, 3, 9, 00, 00, 00).utc, ended_at: Time.new(2014, 4, 9, 00, 00, 00).utc }

    let!(:revenue_event_upgraded) { create :revenue_event, stripe_customer_id: "cus_002", amount: 500, stripe_plan_id: "plan2", event: RevenueEvent::UPGRADED, created_at: Time.new(2014, 3, 9).utc }
    let!(:discount_for_upgrade) { create :applied_discount, stripe_customer_id: "cus_002", percent_off: 10, started_at: Time.new(2014, 3, 9, 00, 00, 00).utc, ended_at: Time.new(2014, 4, 9, 00, 00, 00).utc }

    let!(:revenue_event_downgraded) { create :revenue_event, stripe_customer_id: "cus_003", amount: 500, stripe_plan_id: "plan1", event: RevenueEvent::DOWNGRADED, created_at: Time.new(2014, 3, 9).utc }
    let!(:discount_for_downgrade) { create :applied_discount, stripe_customer_id: "cus_003", percent_off: 10, started_at: Time.new(2014, 3, 9, 00, 00, 00).utc, ended_at: Time.new(2014, 4, 9, 00, 00, 00).utc }

    let!(:revenue_event_canceled) { create :revenue_event, stripe_customer_id: "cus_004", amount: 500, stripe_plan_id: "plan1", event: RevenueEvent::CANCELED, created_at: Time.new(2014, 3, 9).utc }
    let!(:discount_for_cancel) { create :applied_discount, stripe_customer_id: "cus_004", percent_off: 10, started_at: Time.new(2014, 2, 9, 00, 00, 00).utc, ended_at: Time.new(2014, 4, 9, 00, 00, 00).utc }

    let!(:revenue_event_for_existing_subscription) { create :revenue_event, stripe_customer_id: "cus_005", amount: 500, stripe_plan_id: "plan1", event: RevenueEvent::SUBSCRIBED, created_at: Time.new(2014, 2, 9).utc }
    let!(:discount_added_for_existing_subscription) { create :applied_discount, stripe_customer_id: "cus_005", percent_off: 10, started_at: Time.new(2014, 3, 9, 00, 00, 00).utc, ended_at: Time.new(2014, 4, 9, 00, 00, 00).utc }

    let!(:revenue_event_for_expired_discount) { create :revenue_event, stripe_customer_id: "cus_006", amount: 500, stripe_plan_id: "plan1", event: RevenueEvent::SUBSCRIBED, created_at: Time.new(2014, 2, 10).utc }
    let!(:expired_discount) { create :applied_discount, stripe_customer_id: "cus_005", percent_off: 10, started_at: Time.new(2014, 2, 10, 00, 00, 00).utc, ended_at: Time.new(2014, 3, 9, 00, 00, 00).utc }

    before do
      AppliedDiscount.stub(:discounted_value_as_of) { { amount: 100, count: 5 } }
    end

    it 'should calculate the amount and count correctly' do
      output = {
                 starting: { amount: 100, count: 5 },
                 subscribed: { amount: 50, count: 1 },
                 upgraded: { amount: 50, count: 1 },
                 downgraded: { amount: 50, count: 1 },
                 canceled: { amount: 50, count: 1 },
                 added: { amount: 50, count: 1 },
                 expired: { amount: 50, count: 1 },
                 total: { amount: 100, count: 5 }
               }
      expect(AppliedDiscount.data_for_period(Time.new(2014, 3, 8), Time.new(2014, 3, 10))).to eq output
    end
  end
end
