require 'spec_helper'
require 'ostruct'

describe BillingProfile do
  it { should belong_to(:user) }
  it { should have_many(:subscriptions) }
  it { should have_many(:receipts) }

  describe '#active_subscription' do
    let!(:billing_profile) { create :billing_profile }
    let!(:plan) { create :subscription_plan }

    let!(:subscription_1) { create :subscription, state: 'pending', billing_profile: billing_profile, plan: plan }
    let!(:subscription_2) { create :subscription, state: 'pending', billing_profile: billing_profile, plan: plan }

    context 'when user has no active subscription' do
      it 'returns nil' do
        expect(billing_profile.active_subscription).to be_nil
      end
    end

    context 'when user has an active subscription' do
      before do
        subscription_1.update_attribute 'state', 'active'
      end

      it 'returns the active subscription' do
        expect(billing_profile.active_subscription).to eq(subscription_1)
      end
    end

    context 'when user has multiple active subscriptions (accidental context)' do
      before do
        subscription_1.update_attribute 'state', 'active'
        subscription_2.update_attribute 'state', 'active'
      end

      it 'returs the active subscription' do
        expect(billing_profile.active_subscription).to eq(subscription_2)
      end

    end
  end

  describe '#active' do
    let!(:billing_profile) { create :billing_profile }

    context "when there's an active subscription" do
      before do
        billing_profile.stub(:active_subscription).and_return create(:subscription)
      end

      it 'returns true' do
        expect(billing_profile.active).to be_true
      end
    end

    context "when there's no active subscription" do
      before do
        billing_profile.stub(:active_subscription).and_return nil
      end

      it 'returns true' do
        expect(billing_profile.active).to be_false
      end
    end
  end

  describe '#expiry' do
    let!(:billing_profile) { create :billing_profile }

    it 'returns an expiry string' do
      billing_profile.exp_month = 12
      billing_profile.exp_year = 2013

      expect(billing_profile.expiry).to eq("12/2013")
    end
  end

  describe '#formatted_card_number' do
    let!(:billing_profile) { create :billing_profile }

    it 'returns a formatted card number' do
      billing_profile.last_four = 4422

      expect(billing_profile.formatted_card_number).to eq("#############4422")
    end
  end

  describe '#subscribe' do
    let!(:user) { create :user }
    let!(:plan) { create :subscription_plan }
    let!(:stripe_token) { 'stripe_token' }

    context "there's an active subscription" do
      let!(:billing_profile) { create :billing_profile }

      it "shouldn't create another subscription'" do
        billing_profile.stub(:active_subscription).and_return double()
        expect(billing_profile.subscribe stripe_token, plan).to be_false
      end
    end

    context "user has no active subscription" do
      let!(:billing_profile) { user.build_billing_profile }

      context 'when both Stripe token and plan is provided' do
        let!(:stripe_id) { 'stripe_id' }
        let!(:last4) { '4242' }
        let!(:card_type) { 'visa' }
        let!(:exp_month) { 12 }
        let!(:exp_year) { 2013 }

        before do
          @fake_stripe_customer = double()

          @fake_stripe_customer.stub("id").and_return stripe_id
          @fake_stripe_customer.stub_chain("cards.data.first.last4").and_return last4
          @fake_stripe_customer.stub_chain("cards.data.first.type").and_return card_type
          @fake_stripe_customer.stub_chain("cards.data.first.exp_month").and_return exp_month
          @fake_stripe_customer.stub_chain("cards.data.first.exp_year").and_return exp_year

          @fake_stripe_customer.stub(:save)

          Stripe::Customer.stub(:create).and_return @fake_stripe_customer
        end

        it 'creates a new customer in Stripe' do
          Stripe::Customer.should_receive(:create).with(
            email: user.email,
            description: "#{user.username} #{user.email}",
            card: stripe_token,
            plan: plan.stripe_id
          )

          billing_profile.subscribe stripe_token, plan
        end

        it 'should store card properties returned from Stripe' do
          billing_profile.subscribe stripe_token, plan

          expect(billing_profile.stripe_id).to eq(stripe_id)
          expect(billing_profile.last_four).to eq(last4)
          expect(billing_profile.card_type).to eq(card_type)
          expect(billing_profile.exp_month).to eq(exp_month)
          expect(billing_profile.exp_year).to eq(exp_year)
        end
      end

      context 'when stripe token is not provided' do
        it 'does not create a new customer in Stripe' do
          Stripe::Customer.should_not_receive(:create)

          billing_profile.subscribe nil, plan
        end

        it 'should add an error on billing profile and return false' do
          expect(billing_profile.subscribe nil, plan).to be_false
          expect(billing_profile.errors.messages).to include(:base)
        end

        it 'should not save the billing profile' do
          billing_profile.should_not_receive(:save)
          billing_profile.subscribe nil, plan
        end
      end

      context 'when plan is not provided' do
        it 'does not create a new customer in Stripe' do
          Stripe::Customer.should_not_receive(:create)

          billing_profile.subscribe stripe_token, nil
        end

        it 'should add an error on billing profile and return false' do
          expect(billing_profile.subscribe stripe_token, nil).to be_false
          expect(billing_profile.errors.messages).to include(:base)
        end

        it 'should not save the billing profile' do
          billing_profile.should_not_receive(:save)
          billing_profile.subscribe stripe_token, nil
        end
      end

      context 'when Stripe raises some card error' do
        before do
          Stripe::Customer.should_receive(:create).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})
        end

        it 'should add an error on billing profile base and return false' do
          expect(billing_profile.subscribe stripe_token, plan).to be_false
          expect(billing_profile.errors.messages).to include(:base)
        end

        it 'should not save the billing profile' do
          billing_profile.should_not_receive(:save)
          billing_profile.subscribe stripe_token, plan
        end
      end

      context 'when Stripe raises card declined error' do
        before do
          Stripe::Customer.should_receive(:create).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_declined', message: 'stripe error' }})
        end

        it 'should add an error on billing profile base and return false' do
          expect(billing_profile.subscribe stripe_token, plan).to be_false
          expect(billing_profile.errors.messages[:base][0]).to match /Try contacting your bank/
        end

        it 'should not save the billing profile' do
          billing_profile.should_not_receive(:save)
          billing_profile.subscribe stripe_token, plan
        end
      end
    end
  end

  describe '#unsubscribe' do
    let!(:user) { create :user }
    let!(:plan) { create :subscription_plan }

    let!(:billing_profile) { create :billing_profile, user: user }

    context 'when theres no active subscription' do
      it 'returns false' do
        expect(billing_profile.unsubscribe).to be_false
      end
    end

    context 'when theres an active subscription' do
      let!(:subscription) { create :subscription, state: 'active', billing_profile: billing_profile, plan: plan }

      before do
        @fake_stripe_customer = double()
        Stripe::Customer.stub(:retrieve).and_return @fake_stripe_customer
      end

      context "when user's n2o consumption doesnt exceed base n2o" do
        before do
          user.update_attribute 'max_n2o', 1000
          user.update_attribute 'used_n2o', 100
          plan.update_attribute 'n2o_amount', 500

          @fake_stripe_customer.should_receive(:cancel_subscription)
        end

        it 'should cancel Stripe subscription and return true' do
          expect(billing_profile.unsubscribe).to be_true
        end
      end

      context 'when users n2o consumption exceeds base n2o' do
        before do
          user.update_attribute 'max_n2o', 1000
          user.update_attribute 'used_n2o', 600
          plan.update_attribute 'n2o_amount', 500

          @fake_stripe_customer.should_not_receive(:cancel_subscription)
        end

        it 'should add an error on billing profile and return false' do
          expect(billing_profile.unsubscribe).to be_false
          expect(billing_profile.errors.messages).to include(:base)
        end
      end
    end
  end

  describe '#update_subscription' do
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }

    let!(:current_plan) { create :subscription_plan, n2o_amount: 100 }
    let!(:upper_plan) { create :subscription_plan, n2o_amount: 200 }
    let!(:lower_plan) { create :subscription_plan, n2o_amount: 50 }

    let!(:stripe_token) { 'stripe_token' }

    context "when there's no active subscription" do
      it 'returns false' do
        expect(billing_profile.update_subscription stripe_token, upper_plan).to be_false
      end
    end

    context "when there's an active subscription" do
      let!(:subscription) { create :subscription, state: 'active', billing_profile: billing_profile, plan: current_plan }

      let!(:stripe_id) { 'stripe_id' }
      let!(:last4) { '4242' }
      let!(:card_type) { 'visa' }
      let!(:exp_month) { 12 }
      let!(:exp_year) { 2013 }

      before do
        @fake_stripe_customer = double()

        @fake_stripe_customer.stub(:card=)
        @fake_stripe_customer.stub("id").and_return stripe_id
        @fake_stripe_customer.stub_chain("cards.data.first.last4").and_return last4
        @fake_stripe_customer.stub_chain("cards.data.first.type").and_return card_type
        @fake_stripe_customer.stub_chain("cards.data.first.exp_month").and_return exp_month
        @fake_stripe_customer.stub_chain("cards.data.first.exp_year").and_return exp_year

        @fake_stripe_customer.stub(:save)

        Stripe::Customer.stub(:retrieve).and_return @fake_stripe_customer
      end

      context "when Stripe token is present" do
        it "should update the card in Stripe" do
          @fake_stripe_customer.should_receive(:card=).with(stripe_token)
          billing_profile.update_subscription stripe_token, nil
        end

        it 'should save the updated card properties returned from Stripe' do
          billing_profile.update_subscription stripe_token, nil
          billing_profile.reload

          expect(billing_profile.stripe_id).to eq(stripe_id)
          expect(billing_profile.last_four).to eq(last4)
          expect(billing_profile.card_type).to eq(card_type)
          expect(billing_profile.exp_month).to eq(exp_month)
          expect(billing_profile.exp_year).to eq(exp_year)
        end

        context 'when Stripe raises some card error' do
          before do
            @fake_stripe_customer.should_receive(:save).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})
          end

          it 'should add an error on billing profile base and return false' do
            expect(billing_profile.update_subscription stripe_token, upper_plan).to be_false
            expect(billing_profile.errors.messages).to include(:base)
          end

          it 'should not save the billing profile' do
            billing_profile.should_not_receive(:save)
            billing_profile.update_subscription stripe_token, upper_plan
          end

          it 'should not attempt to update the plan' do
            @fake_stripe_customer.should_not_receive(:update_subscription)
            billing_profile.update_subscription stripe_token, upper_plan
          end
        end

        context 'when Stripe raises some card error' do
          before do
            @fake_stripe_customer.should_receive(:save).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_declined', message: 'stripe error' }})
          end

          it 'should add an error on billing profile base and return false' do
            expect(billing_profile.update_subscription stripe_token, upper_plan).to be_false
            expect(billing_profile.errors.messages[:base][0]).to match /Try contacting your bank/
          end

          it 'should not save the billing profile' do
            billing_profile.should_not_receive(:save)
            billing_profile.update_subscription stripe_token, upper_plan
          end

          it 'should not attempt to update the plan' do
            @fake_stripe_customer.should_not_receive(:update_subscription)
            billing_profile.update_subscription stripe_token, upper_plan
          end
        end
      end

      context "when a new plan is provided" do
        context "the new plan gives more n2o than what user is currently utitlizing" do
          before do
            user.update_attribute 'max_n2o', 200
            user.update_attribute 'used_n2o', 100
          end

          it "should change user's Stripe subscription" do
            @fake_stripe_customer.should_receive(:update_subscription).with(plan: upper_plan.stripe_id)
            expect(billing_profile.update_subscription nil, upper_plan)
          end
        end

        context 'the new plan gives less n2o than what user is currently utitlizing' do
          before do
            user.update_attribute 'max_n2o', 200
            user.update_attribute 'used_n2o', 150
          end

          it "should not update user's Stripe subscription" do
            @fake_stripe_customer.should_not_receive(:update_subscription)
            expect(billing_profile.update_subscription nil, lower_plan)
          end

          it 'should add an error on billing profile and return false' do
            expect(billing_profile.update_subscription nil, lower_plan).to be_false
            expect(billing_profile.errors.messages).to include(:base)
          end
        end
      end
    end
  end

  describe '#push_billing_profile_updated_message' do
    let!(:plan) { create :subscription_plan }
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }

    it 'pushes aio:billing_profile_updated notification' do
      channel = double('channel')
      Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
      channel.should_receive(:trigger).ordered.with('aio:billing_profile_updated', billing_profile.serialize_as_hash)

      billing_profile.push_billing_profile_updated_message
    end
  end

  describe '#deliver_card_updated_mail' do
    let!(:billing_profile) { create :billing_profile }

    it 'should deliver card updated mail' do
      expect {
        billing_profile.deliver_card_updated_mail
      }.to change(Delayed::Job, :count).by(1) 

      Delayed::Job.first.handler.should =~ /'SubscriptionMailer'\nmethod_name: :credit_card_changed_alert\nargs:\n- #{billing_profile.id}\n/
    end
  end

  describe '.handle_stripe_event' do
    let!(:user) { create :user }
    let!(:stripe_id) { 'stripe_id' }
    let!(:plan) { create :subscription_plan, stripe_id: stripe_id }
    let!(:billing_profile) { create :billing_profile, stripe_id: stripe_id, user: user }

    let!(:subscription_1) { create :subscription, billing_profile: billing_profile, plan: plan }
    let!(:subscription_2) { create :subscription, billing_profile: billing_profile, plan: plan }

    before do
      allow_any_instance_of(BillingProfile).to receive(:push_billing_profile_updated_message)
    end

    context 'when a billing profile exists for the given stripe id' do
      context 'subscription_created event' do
        context 'when an active subscription doesnt exist for the billing profile' do
          it 'creates an active subscription for the given plan' do
            expect {
              BillingProfile.handle_stripe_event 'subscription_created', stripe_id, { plan_id: stripe_id }
            }.to change { Subscription.count }.by 1

            subscription = Subscription.last
            expect(subscription.billing_profile).to eq(billing_profile)
            expect(subscription.plan).to eq(plan)
            expect(subscription.state).to eq("active")
          end
        end

        context 'when an active subscription exists for the billing profile' do
          before do
            create :subscription, state: 'active', plan: plan, billing_profile: billing_profile
          end

          it 'does not create another subscription' do
            expect {
              BillingProfile.handle_stripe_event 'subscription_created', stripe_id, { plan_id: stripe_id }
            }.to_not change { Subscription.count }
          end
        end
      end

      context 'charge_failed event' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'changes active subscription to payment due' do
          BillingProfile.handle_stripe_event 'charge_failed', stripe_id
          expect(subscription_2.reload.state).to eq('payment_due')
        end
      end

      context 'subscription_changed event' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'cancels the active subscription' do
          BillingProfile.handle_stripe_event 'subscription_changed', stripe_id, { plan_id: stripe_id }
          expect(subscription_2.reload.state).to eq('canceled')
        end

        it 'creates an active subscription for the given plan' do
          expect {
            BillingProfile.handle_stripe_event 'subscription_changed', stripe_id, { plan_id: stripe_id }
          }.to change { Subscription.count }.by 1

          subscription = Subscription.last
          expect(subscription.billing_profile).to eq(billing_profile)
          expect(subscription.plan).to eq(plan)
          expect(subscription.state).to eq("active")
        end

        context 'when the new plan is a downgrade from the old plan' do
          let!(:new_plan) { create :subscription_plan, stripe_id: 10 }

          before do
            SubscriptionPlan.stub(:find_by_stripe_id).with(10) { new_plan }
            new_plan.stub(:is_downgrade_from).with(subscription_plan) { true }
          end

          it 'should queue a job to downgrade boxes if the new plan is a downgrade from the old plan' do
            DowngradeBoxesJob.should_receive(:submit_job).with(user.id)
            BillingProfile.handle_event_from_stripe stripe_id, 'subscription_changed', { plan_id: 10 }
          end
        end

        context 'when the new plan is not a downgrade from the old plan' do
          let!(:new_plan) { create :subscription_plan, stripe_id: 11 }

          before do
            SubscriptionPlan.stub(:find_by_stripe_id).with(11) { new_plan }
            new_plan.stub(:is_downgrade_from).with(subscription_plan) { false }
          end

          it 'should not queue a job to downgrade boxes if the new plan is not a downgrade from the old plan' do
            DowngradeBoxesJob.should_not_receive(:submit_job)
            BillingProfile.handle_event_from_stripe stripe_id, 'subscription_changed', { plan_id: 11 }
          end
        end
      end

      context 'subscription_canceled event' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'cancels the active subscription' do
          BillingProfile.handle_stripe_event 'subscription_canceled', stripe_id
          expect(subscription_2.reload.state).to eq('canceled')
        end

        it 'should queue a job to downgrade boxes' do
          DowngradeBoxesJob.should_receive(:submit_job).with(user.id)
          BillingProfile.handle_event_from_stripe stripe_id, 'subscription_canceled'
        end
      end

      context 'payment_succeeded event' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        let!(:period_start) { Time.new(2013, 10, 1) }
        let!(:period_end) { Time.new(2013, 10, 31) }
        let!(:receipt_details) do
          {
            period_start: period_start.to_i,
            period_end: period_end.to_i,
            lines: [{
              "amount" => 500,
              "currency" => "usd",
              "quantity" => 1,
              "description" => nil,
              "plan" => {
                "name" => "500 N2O"
              }
            }],
            subtotal: 500,
            total: 500
          }
        end

        it 'creates a new receipt for the billing profile' do
          expect {
            BillingProfile.handle_stripe_event 'payment_succeeded', stripe_id, { receipt_details: receipt_details }
          }.to change { Receipt.count }.by 1

          receipt = Receipt.last
          expect(receipt.billing_profile).to eq(billing_profile)
          expect(receipt.period_start).to eq(period_start)
          expect(receipt.period_end).to eq(period_end)
          expect(receipt.subtotal).to eq(500)
          expect(receipt.total).to eq(500)
          expect(receipt.lines).to eq(receipt_details[:lines])
        end

        it "should track revenue on Mixpanel" do
          user = billing_profile.user
          TrackMixpanelRevenueJob.should_receive(:submit_job).with(user.id, plan.price)
          BillingProfile.handle_stripe_event 'payment_succeeded', stripe_id, { receipt_details: receipt_details }
        end
      end

      context 'card_updated event' do
        it 'sends a notification mail to the user' do
          BillingProfile.handle_stripe_event 'card_updated', stripe_id
          SubscriptionMailer.should_receive(:credit_card_changed_alert).with(billing_profile.id) { double(:nothing, deliver: nil) }
          Delayed::Job.last.invoke_job
        end
      end
    end
  end

  describe '.find_profiles_with_expiring_cards' do
    let!(:plan) { create :subscription_plan }

    let!(:billing_profile_1) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_2) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_3) { create :billing_profile, exp_month: 11, exp_year: 2013 }

    let!(:subscription_1) { create :subscription, state: 'active', billing_profile: billing_profile_1, plan: plan }
    let!(:subscription_2) { create :subscription, state: 'canceled', billing_profile: billing_profile_2, plan: plan }
    let!(:subscription_3) { create :subscription, state: 'active', billing_profile: billing_profile_3, plan: plan }

    context 'when a valid date is provided' do
      before do
        @date = Time.utc(2013, 9)
      end

      it 'should return only active profiles expiring in the given month' do
        BillingProfile.find_profiles_with_expiring_cards(@date).should eq [billing_profile_1]
      end
    end

    context 'when the date is nil' do
      before do
        @date = nil
      end

      it 'should not return any profiles' do
        BillingProfile.find_profiles_with_expiring_cards(@date).should eq nil
      end
    end
  end

end
