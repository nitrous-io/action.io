require 'spec_helper'
require 'ostruct'

shared_examples_for 'an instance that retrieves and stores values from Stripe' do
  before do
    billing_profile.save
  end

  it 'should retrieve and store the last four digits of the active credit card in Stripe' do
    expect(billing_profile.reload.last_four).to eq(stripe_customer.cards.data.first.last4)
  end

  it 'should retrieve and store the card type of the active credit card in Stripe' do
    expect(billing_profile.reload.card_type).to eq(stripe_customer.cards.data.first.type)
  end

  it 'should retrieve and store the expiry month of the active credit card in Stripe' do
    expect(billing_profile.reload.exp_month).to eq(stripe_customer.cards.data.first.exp_month)
  end

  it 'should retrieve and store the expiry year of the active credit card in Stripe' do
    expect(billing_profile.reload.exp_year).to eq(stripe_customer.cards.data.first.exp_year)
  end

  it 'should retrieve and store the id of the customer in Stripe' do
    expect(billing_profile.reload.stripe_id).to eq(stripe_customer.id)
  end
end

describe BillingProfile do
  it { should allow_mass_assignment_of :stripe_token }
  it { should allow_mass_assignment_of :plan }

  it { should belong_to(:user) }
  it { should have_many(:subscriptions) }

  describe 'creating a new billing profile' do
    let!(:user) { create :user }
    let!(:plan) { create :subscription_plan }

    let!(:stripe_token) { 'abcdefghijk' }
    let!(:stripe_customer) do
      OpenStruct.new(id: 'id_01',
                     cards: OpenStruct.new(
                       data: [ OpenStruct.new(last4: '1234', type: 'Visa', exp_month: 10, exp_year: 2014 ) ]
                    ))
    end

    let(:billing_profile) { build :billing_profile_with_callbacks, user: user }

    context 'both stripe token and plan is present' do
      before do
        Stripe::Customer.should_receive(:create).with(
          email: user.email,
          description: "#{user.username} #{user.email}",
          card: stripe_token,
          plan: plan.stripe_id
        ).and_return stripe_customer

        billing_profile.stripe_token = stripe_token
        billing_profile.plan = plan

        billing_profile.should_receive :push_billing_profile_updated_message
      end

      it 'creates a new customer in Stripe' do
        billing_profile.save
      end

      it 'clears the stripe token after saving the record' do
        billing_profile.save
        expect(billing_profile.stripe_token).to be_nil
      end

      it_behaves_like 'an instance that retrieves and stores values from Stripe'
    end

    context 'plan is not present' do
      before do
        billing_profile.stripe_token = stripe_token
        billing_profile.plan = nil
      end

      it 'should not create a customer' do
        Stripe::Customer.should_not_receive(:create)
        billing_profile.save
      end

      it 'should add an error on plan' do
        billing_profile.save
        expect(billing_profile).to have(1).error_on(:plan)
      end
    end

    context 'stripe_token is not present' do
      before do
        billing_profile.stripe_token = nil
        billing_profile.plan = plan
      end

      it 'should not create a customer' do
        Stripe::Customer.should_not_receive(:create)
        billing_profile.save
      end

      it 'should add an invalid request error to base' do
        billing_profile.save
        expect(billing_profile.errors.messages).to include(base: ["invalid request"])
      end
    end

    context 'stripe raises a card error' do
      before do
        Stripe::Customer.should_receive(:create).with(
          email: user.email,
          description: "#{user.username} #{user.email}",
          card: stripe_token,
          plan: plan.stripe_id
        ).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})

        billing_profile.stripe_token = stripe_token
        billing_profile.plan = plan
      end

      it 'should not create a new billing profile' do
        expect {
          billing_profile.save
        }.to_not change{BillingProfile.count}.by(1)
      end

      it 'should add stripe card error to base' do
        billing_profile.save
        expect(billing_profile.errors.messages).to include(base: ["stripe error"])
      end
    end
  end

  describe 'updating a billing profile' do
    let!(:user) { create :user }
    let!(:old_plan) { create :subscription_plan }
    let!(:new_plan) { create :subscription_plan }

    let!(:stripe_token) { 'abcdefghijk' }
    let!(:stripe_customer) { OpenStruct.new(id: 'id_01',
                                            cards: OpenStruct.new(
                                              data: [ OpenStruct.new(last4: '1234', type: 'Visa', exp_month: 10, exp_year: 2014 ) ]
                                            ))
                           }

    let!(:billing_profile) { create :billing_profile, user: user, plan: old_plan }
    let!(:subscription) { create :subscription, state: 'active', billing_profile: billing_profile, subscription_plan: old_plan }

    before do
      billing_profile.class.set_callback(:save, :before, :create_or_update_stripe_customer)
      billing_profile.class.set_callback(:save, :before, :change_plan)
      billing_profile.class.set_callback(:save, :after,  :push_billing_profile_updated_message)
      Stripe::Customer.should_receive(:retrieve).with(billing_profile.stripe_id).and_return stripe_customer
    end

    context 'updating stripe customer' do
      before do
        stripe_customer.stub(:save)

        billing_profile.plan = nil
        billing_profile.should_receive :push_billing_profile_updated_message
      end

      context 'credit card is changed' do
        before do
          billing_profile.stripe_token = stripe_token
        end

        it "should set the given stripe token as the stripe customer's card" do
          stripe_customer.should_receive(:card=).with(stripe_token)
          billing_profile.save
        end
      end

      context 'credit card is not changed, but associated user email is changed' do
        before do
          billing_profile.stripe_token = nil
        end

        it "should set the modified user email as the stripe customer's email" do
          stripe_customer.should_receive(:email=).with(user.email)
          billing_profile.save
        end
      end

      it_behaves_like 'an instance that retrieves and stores values from Stripe'
    end

    context 'changing the existing plan' do
      before do
        billing_profile.plan = new_plan
        billing_profile.should_receive :push_billing_profile_updated_message
      end

      context 'when theres no active subscription' do
        before do
          billing_profile.stub(:active_subscription).and_return nil
        end

        it 'should call update_subscription on stripe customer' do
          stripe_customer.should_receive(:update_subscription).with(plan: new_plan.stripe_id)
          billing_profile.save
        end
      end

      context 'when user selects a plan that gives more n2o than what he currently use' do
        before do
          user.update_attribute 'max_n2o', 1000
          user.update_attribute 'used_n2o', 500

          old_plan.update_attribute 'n2o_amount', 1000
          new_plan.update_attribute 'n2o_amount', 2000
        end

        it 'should call update_subscription on stripe customer' do
          stripe_customer.should_receive(:update_subscription).with(plan: new_plan.stripe_id)
          billing_profile.save
        end
      end

      context 'when user selects a plan that gives less n2o than what he currently use' do
        before do
          user.update_attribute 'max_n2o', 1000
          user.update_attribute 'used_n2o', 500

          old_plan.update_attribute 'n2o_amount', 1000
          new_plan.update_attribute 'n2o_amount', 250
        end

        it 'should not call update_subscription on stripe customer' do
          stripe_customer.should_not_receive(:update_subscription).with(plan: new_plan.stripe_id)
          billing_profile.save
        end

        it 'should add an error on billing profile' do
          billing_profile.save
          expect(billing_profile.errors.messages).to include(:base)
        end
      end
    end
  end

  describe 'canceling a subscription' do
    let!(:user) { create :user }
    let!(:plan) { create :subscription_plan }

    let!(:billing_profile) { create :billing_profile, user: user, plan: plan }

    context 'when theres no active subscription' do
      it 'returns false' do
        expect(billing_profile.cancel_subscription).to be_false
      end
    end

    context 'when theres an active subscription' do
      let!(:subscription) { create :subscription, state: 'active', billing_profile: billing_profile, subscription_plan: plan }

      before do
        @fake_stripe_customer = double()
        Stripe::Customer.stub(:retrieve).and_return @fake_stripe_customer
      end

      context 'when users n2o consumption doesnt exceed base n2o' do
        before do
          user.update_attribute 'max_n2o', 1000
          user.update_attribute 'used_n2o', 100
          plan.update_attribute 'n2o_amount', 500

          @fake_stripe_customer.should_receive(:cancel_subscription)
        end

        it 'should cancel stripe subscription and return true' do
          expect(billing_profile.cancel_subscription).to be_true
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
          expect(billing_profile.cancel_subscription).to be_false
          expect(billing_profile.errors.messages).to include(:base)
        end
      end
    end
  end

  describe '#push_billing_profile_updated_message' do
    let!(:plan) { create :subscription_plan }
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, plan: plan, user: user }

    it 'pushes aio:billing_profile_updated notification' do
      channel = double('channel')
      Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
      channel.should_receive(:trigger).ordered.with('aio:billing_profile_updated', billing_profile.serialize_as_hash)

      billing_profile.push_billing_profile_updated_message
    end
  end

  describe '.handle_event_from_stripe' do
    let!(:stripe_id) { "stripe_id" }
    let!(:subscription_plan) { create :subscription_plan, stripe_id: stripe_id }
    let!(:billing_profile) { create :billing_profile, stripe_id: stripe_id, plan: subscription_plan }

    let!(:subscription_1) { create :subscription, billing_profile: billing_profile, subscription_plan: subscription_plan }
    let!(:subscription_2) { create :subscription, billing_profile: billing_profile, subscription_plan: subscription_plan }

    before do
      allow_any_instance_of(BillingProfile).to receive(:push_billing_profile_updated_message)
    end

    context 'when a billing profile exist for the given stripe id' do
      context 'the event is subscription_created' do
        context 'when an active subscription doesnt exist for the billing profile' do
          it 'creates an active subscription for the given plan' do
            expect {
              BillingProfile.handle_event_from_stripe stripe_id, 'subscription_created', { plan_id: stripe_id }
            }.to change { Subscription.count }.by 1

            subscription = Subscription.last
            expect(subscription.billing_profile).to eq(billing_profile)
            expect(subscription.subscription_plan).to eq(subscription_plan)
            expect(subscription.state).to eq("active")
          end
        end

        context 'when an active subscription exist for the billing profile ' do
          before do
            create :subscription, state: 'active', subscription_plan: subscription_plan, billing_profile: billing_profile
          end

          it 'does not create another subscription' do
            expect {
              BillingProfile.handle_event_from_stripe stripe_id, 'subscription_created', { plan_id: stripe_id }
            }.to_not change { Subscription.count }
          end
        end
      end

      context 'the event is charge_failed' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'changes active subscription to payment due' do
          BillingProfile.handle_event_from_stripe stripe_id, 'charge_failed'
          expect(subscription_2.reload.state).to eq('payment_due')
        end
      end

      context 'the event is subscription_changed' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'cancels the active subscription' do
          BillingProfile.handle_event_from_stripe stripe_id, 'subscription_changed', { plan_id: stripe_id }
          expect(subscription_2.reload.state).to eq('canceled')
        end

        it 'creates an active subscription for the given plan' do
          expect {
            BillingProfile.handle_event_from_stripe stripe_id, 'subscription_changed', { plan_id: stripe_id }
          }.to change { Subscription.count }.by 1

          subscription = Subscription.last
          expect(subscription.billing_profile).to eq(billing_profile)
          expect(subscription.subscription_plan).to eq(subscription_plan)
          expect(subscription.state).to eq("active")
        end
      end

      context 'the event is subscription_canceled' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'cancels the active subscription' do
          BillingProfile.handle_event_from_stripe stripe_id, 'subscription_canceled'
          expect(subscription_2.reload.state).to eq('canceled')
        end
      end

      context 'the event is payment_succeeded' do
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
            BillingProfile.handle_event_from_stripe stripe_id, 'payment_succeeded', { receipt_details: receipt_details }
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
          TrackMixpanelRevenueJob.should_receive(:submit_job).with(user.id, subscription_plan.price)
          BillingProfile.handle_event_from_stripe stripe_id, 'payment_succeeded', { receipt_details: receipt_details }
        end
      end

      context 'the event is card_updated' do
        it 'sends a mail notifying the user that the card has been updated' do
          BillingProfile.handle_event_from_stripe stripe_id, 'card_updated'
          SubscriptionMailer.should_receive(:credit_card_changed_alert).with(billing_profile.id) { double(:nothing, deliver: nil) }
          Delayed::Job.last.invoke_job
        end
      end
    end
  end

  describe '.find_profiles_with_expiring_cards', focus: true do
    let!(:subscription_plan) { create :subscription_plan }

    let!(:billing_profile_1) { create :billing_profile, plan: subscription_plan, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_2) { create :billing_profile, plan: subscription_plan, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_3) { create :billing_profile, plan: subscription_plan, exp_month: 11, exp_year: 2013 }

    let!(:subscription_1) { create :subscription, state: 'active', billing_profile: billing_profile_1, subscription_plan: subscription_plan }
    let!(:subscription_2) { create :subscription, state: 'canceled', billing_profile: billing_profile_2, subscription_plan: subscription_plan }
    let!(:subscription_3) { create :subscription, state: 'active', billing_profile: billing_profile_3, subscription_plan: subscription_plan }

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
