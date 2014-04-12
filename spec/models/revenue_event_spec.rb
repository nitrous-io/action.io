require 'spec_helper'

describe RevenueEvent do
  it { should allow_mass_assignment_of :event }
  it { should allow_mass_assignment_of :amount }
  it { should allow_mass_assignment_of :created_at }
  it { should allow_mass_assignment_of :stripe_id }
  it { should allow_mass_assignment_of :stripe_plan_id }

  describe 'scopes' do
    let!(:revenue_event_1) { create :revenue_event, event: RevenueEvent::SUBSCRIBED, created_at: Time.new(2014, 3, 10).utc }
    let!(:revenue_event_2) { create :revenue_event, event: RevenueEvent::UPGRADED, created_at: Time.new(2014, 3, 15).utc }
    let!(:revenue_event_3) { create :revenue_event, event: RevenueEvent::DOWNGRADED, created_at: Time.new(2014, 3, 20).utc }
    let!(:revenue_event_4) { create :revenue_event, event: RevenueEvent::CANCELED, created_at: Time.new(2014, 4, 10).utc }
    let!(:revenue_event_5) { create :revenue_event, event: RevenueEvent::BILLED, created_at: Time.new(2014, 4, 10).utc }
    let!(:revenue_event_6) { create :revenue_event, event: RevenueEvent::CHARGED, created_at: Time.new(2014, 4, 10).utc }
    let!(:revenue_event_7) { create :revenue_event, event: RevenueEvent::REFUNDED, created_at: Time.new(2014, 4, 10).utc }

    # some edge cases for in_period boundary checking
    let!(:revenue_event_8) { create :revenue_event, created_at: Time.new(2014, 3, 31, 23, 59, 59).utc }
    let!(:revenue_event_9) { create :revenue_event, created_at: Time.new(2014, 4, 1, 00, 00, 01).utc }
    let!(:revenue_event_10) { create :revenue_event, created_at: Time.new(2014, 2, 28, 23, 59, 59).utc }

    context 'subscribed' do
      it "should return the events with type RevenueEvent::SUBSCRIBED" do
        expect(RevenueEvent.subscribed.to_a).to match_array([revenue_event_1])
      end
    end

    context 'upgraded' do
      it "should return the events with type RevenueEvent::UPGRADED" do
        expect(RevenueEvent.upgraded.to_a).to match_array([revenue_event_2])
      end
    end

    context 'downgraded' do
      it "should return the events with type RevenueEvent::DOWNGRADED" do
        expect(RevenueEvent.downgraded.to_a).to match_array([revenue_event_3])
      end
    end

    context 'canceled' do
      it "should return the events with type RevenueEvent::CANCELED" do
        expect(RevenueEvent.canceled.to_a).to match_array([revenue_event_4])
      end
    end

    context 'billed' do
      it "should return the events with type RevenueEvent::BILLED" do
        expect(RevenueEvent.billed.to_a).to match_array([revenue_event_5])
      end
    end

    context 'charged' do
      it "should return the events with type RevenueEvent::CHARGED" do
        expect(RevenueEvent.charged.to_a).to match_array([revenue_event_6])
      end
    end

    context 'refunded' do
      it "should return the events with type RevenueEvent::REFUNDED" do
        expect(RevenueEvent.refunded.to_a).to match_array([revenue_event_7])
      end
    end

    context 'in_period' do
      it "should return only the events created within the period" do
        period_start = Time.new(2014, 3, 1)
        period_end = Time.new(2014, 3, 31)

        expect(RevenueEvent.in_period(period_start, period_end).to_a).to match_array([revenue_event_1, revenue_event_2, revenue_event_3, revenue_event_8])
      end
    end
  end

  describe '.recurring_revenue_for_period' do
    before do
      # events for given period
      create :revenue_event, event: RevenueEvent::SUBSCRIBED, amount: 20000, created_at: Time.new(2014, 3, 1, 00, 00, 00).utc
      create :revenue_event, event: RevenueEvent::UPGRADED, amount: 5000, created_at: Time.new(2014, 3, 15).utc
      create :revenue_event, event: RevenueEvent::DOWNGRADED, amount: 3000, created_at: Time.new(2014, 3, 20).utc
      create :revenue_event, event: RevenueEvent::CANCELED, amount: 2000, created_at: Time.new(2014, 3, 31, 23, 59, 59).utc

      # event just before the period start
      create :revenue_event, event: RevenueEvent::SUBSCRIBED, amount: 20000, created_at: Time.new(2014, 2, 28, 23, 59, 59).utc

      # events just after the period end
      create :revenue_event, event: RevenueEvent::SUBSCRIBED, amount: 20000, created_at: Time.new(2014, 4, 1, 00, 00, 01).utc
    end

    it 'calculates recurring revenue for the given period' do
      period_start = Time.new(2014, 3, 1)
      period_end = Time.new(2014, 3, 31)

      expect(RevenueEvent.recurring_revenue_for_period period_start, period_end).to eq (20000 + 5000 - 3000 - 2000)
    end
  end

  describe '.subscribers_for_period' do
    before do
      # events for given period
      create :revenue_event, event: RevenueEvent::SUBSCRIBED, amount: 20000, created_at: Time.new(2014, 3, 1, 00, 00, 00).utc
      create :revenue_event, event: RevenueEvent::SUBSCRIBED, amount: 20000, created_at: Time.new(2014, 3, 2, 00, 00, 00).utc
      create :revenue_event, event: RevenueEvent::SUBSCRIBED, amount: 20000, created_at: Time.new(2014, 3, 3, 00, 00, 00).utc
      create :revenue_event, event: RevenueEvent::CANCELED, amount: 2000, created_at: Time.new(2014, 3, 31, 23, 59, 59).utc

      # event just before the period start
      create :revenue_event, event: RevenueEvent::SUBSCRIBED, amount: 20000, created_at: Time.new(2014, 2, 28, 23, 59, 59).utc

      # events just after the period end
      create :revenue_event, event: RevenueEvent::SUBSCRIBED, amount: 20000, created_at: Time.new(2014, 4, 1, 00, 00, 01).utc
    end

    it 'counts the subscribers at the end of the given period' do
      period_start = Time.new(2014, 3, 1)
      period_end = Time.new(2014, 3, 31)

      expect(RevenueEvent.subscribers_for_period period_start, period_end).to eq 2
    end
  end

  describe '.subscriptions_billed_in_period' do
    before do
      # events for given period
      create :revenue_event, event: RevenueEvent::BILLED, amount: 2000, stripe_plan_id: "n2o_600", created_at: Time.new(2014, 3, 1, 00, 00, 00).utc
      create :revenue_event, event: RevenueEvent::BILLED, amount: 3000, stripe_plan_id: "n2o_600", created_at: Time.new(2014, 3, 20).utc

      # event without a plan set
      create :revenue_event, event: RevenueEvent::BILLED, amount: 3000, stripe_plan_id: nil, created_at: Time.new(2014, 3, 20).utc

      # event just before the period start
      create :revenue_event, event: RevenueEvent::BILLED, amount: 2000, stripe_plan_id: "n2o_600", created_at: Time.new(2014, 2, 28, 23, 59, 59).utc

      # events just after the period end
      create :revenue_event, event: RevenueEvent::BILLED, amount: 2000, stripe_plan_id: "n2o_600", created_at: Time.new(2014, 4, 1, 00, 00, 01).utc
    end

    it 'calculates total billed within the period' do
      period_start = Time.new(2014, 3, 1)
      period_end = Time.new(2014, 3, 31)

      expect(RevenueEvent.subscriptions_billed_in_period period_start, period_end).to eq 5000
    end
  end

  describe '.collected_in_period' do
    before do
      # events for given period
      create :revenue_event, event: RevenueEvent::CHARGED, amount: 2000, created_at: Time.new(2014, 3, 1, 00, 00, 00).utc
      create :revenue_event, event: RevenueEvent::CHARGED, amount: 3000, created_at: Time.new(2014, 3, 20).utc
      create :revenue_event, event: RevenueEvent::REFUNDED, amount: 1000, created_at: Time.new(2014, 3, 20).utc

      # event just before the period start
      create :revenue_event, event: RevenueEvent::CHARGED, amount: 2000, created_at: Time.new(2014, 2, 28, 23, 59, 59).utc

      # events just after the period end
      create :revenue_event, event: RevenueEvent::CHARGED, amount: 2000, created_at: Time.new(2014, 4, 1, 00, 00, 01).utc
    end

    it 'calculates total collected within the period' do
      period_start = Time.new(2014, 3, 1)
      period_end = Time.new(2014, 3, 31)

      expect(RevenueEvent.collected_in_period period_start, period_end).to eq 4000
    end
  end

  describe '.export_to_csv' do
    context 'when unit is weekly' do
      it 'presents data split by week' do
        expected_output = <<-eos
Period,Starting MRR,Upgrades,Downgrades,Churn,New Subscriptions,Ending MRR (Committed),Total Billed (Invoiced),Total Collected
2014-01-26 - 2014-02-01,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-02-02 - 2014-02-08,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-02-09 - 2014-02-15,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-02-16 - 2014-02-22,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-02-23 - 2014-03-01,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-03-02 - 2014-03-08,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-03-09 - 2014-03-15,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-03-16 - 2014-03-22,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-03-23 - 2014-03-29,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-03-30 - 2014-04-05,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
        eos
        generated_output = RevenueEvent.export_to_csv 'weekly', Date.new(2014, 02, 01), Date.new(2014, 03, 31)
        expect(generated_output).to eq expected_output
      end
    end

    context 'when unit is monthly' do
      it 'presents data split by month' do
        expected_output = <<-eos
Period,Starting MRR,Upgrades,Downgrades,Churn,New Subscriptions,Ending MRR (Committed),Total Billed (Invoiced),Total Collected
2014-02-01 - 2014-02-28,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-03-01 - 2014-03-31,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
2014-04-01 - 2014-04-30,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
        eos
        generated_output = RevenueEvent.export_to_csv 'monthly', Date.new(2014, 02, 01), Date.new(2014, 03, 31)
        expect(generated_output).to eq expected_output
      end
    end
  end

  describe 'calculate_stripe_fees' do
    it 'should calculate the stripe fees provided charge amount, charge count, refund amount and refund count' do
      # Assuming we apply the standard stripe pricing
      # 2.9% and 30 cents for transaction
      expect(RevenueEvent.calculate_stripe_fees 2000, 10, 1000, 1).to eq 299
    end
  end
end
