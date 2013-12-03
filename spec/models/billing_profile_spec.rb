require 'spec_helper'
require 'ostruct'

describe BillingProfile do
  it { should belong_to(:user) }
  it { should have_many(:subscriptions) }
  it { should have_many(:receipts) }

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
    let!(:plan) { create :plan }
    let!(:stripe_token) { 'stripe_token' }

    context "there's an active subscription" do
      let!(:billing_profile) { create :billing_profile }

      before do
        billing_profile.stub(:active_subscription).and_return double()
      end

      it 'adds an error on billing profile and return false' do
        expect(billing_profile.subscribe nil, plan).to be_false
        expect(billing_profile.errors.messages).to include(:base)
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
          billing_profile.stub(:push_billing_profile_updated_message)
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

        it 'stores card properties returned from Stripe' do
          billing_profile.subscribe stripe_token, plan

          expect(billing_profile.stripe_id).to eq(stripe_id)
          expect(billing_profile.last_four).to eq(last4)
          expect(billing_profile.card_type).to eq(card_type)
          expect(billing_profile.exp_month).to eq(exp_month)
          expect(billing_profile.exp_year).to eq(exp_year)
        end

        it 'sends a push notification to the frontend' do
          billing_profile.should_receive(:push_billing_profile_updated_message)
          billing_profile.subscribe stripe_token, plan
        end
      end

      context 'when stripe token is not provided' do
        it 'does not create a new customer in Stripe' do
          Stripe::Customer.should_not_receive(:create)

          billing_profile.subscribe nil, plan
        end

        it 'adds an error on billing profile and return false' do
          expect(billing_profile.subscribe nil, plan).to be_false
          expect(billing_profile.errors.messages).to include(:base)
        end

        it 'does not save the billing profile' do
          billing_profile.should_not_receive(:save)
          billing_profile.subscribe nil, plan
        end
      end

      context 'when plan is not provided' do
        it 'does not create a new customer in Stripe' do
          Stripe::Customer.should_not_receive(:create)

          billing_profile.subscribe stripe_token, nil
        end

        it 'adds an error on billing profile and return false' do
          expect(billing_profile.subscribe stripe_token, nil).to be_false
          expect(billing_profile.errors.messages).to include(:base)
        end

        it 'does not save the billing profile' do
          billing_profile.should_not_receive(:save)
          billing_profile.subscribe stripe_token, nil
        end
      end

      context 'when Stripe raises some card error' do
        before do
          Stripe::Customer.should_receive(:create).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})
        end

        it 'adds an error on billing profile base and return false' do
          expect(billing_profile.subscribe stripe_token, plan).to be_false
          expect(billing_profile.errors.messages).to include(:base)
        end

        it 'does not save the billing profile' do
          billing_profile.should_not_receive(:save)
          billing_profile.subscribe stripe_token, plan
        end
      end

      context 'when Stripe raises card declined error' do
        before do
          Stripe::Customer.should_receive(:create).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_declined', message: 'stripe error' }})
        end

        it 'adds an error on billing profile base and return false' do
          expect(billing_profile.subscribe stripe_token, plan).to be_false
          expect(billing_profile.errors.messages[:base][0]).to match /Try contacting your bank/
        end

        it 'does not save the billing profile' do
          billing_profile.should_not_receive(:save)
          billing_profile.subscribe stripe_token, plan
        end
      end
    end
  end

  describe '#unsubscribe' do
    let!(:user) { create :user }
    let!(:plan) { create :plan }

    let!(:billing_profile) { create :billing_profile, user: user }

    context 'when theres no active subscription' do
      it 'adds an error on billing profile and return false' do
        expect(billing_profile.unsubscribe).to be_false
        expect(billing_profile.errors.messages).to include(:base)
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

        it 'cancels Stripe subscription and return true' do
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

        it 'adds an error on billing profile and return false' do
          expect(billing_profile.unsubscribe).to be_false
          expect(billing_profile.errors.messages).to include(:base)
        end
      end
    end
  end

  describe '#update_subscription' do
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }

    let!(:current_plan) { create :plan, n2o_amount: 100 }
    let!(:upper_plan) { create :plan, n2o_amount: 200 }
    let!(:lower_plan) { create :plan, n2o_amount: 50 }

    let!(:stripe_token) { 'stripe_token' }

    context "when there's no active subscription" do
      it 'adds an error on billing profile base and return false' do
        expect(billing_profile.update_subscription stripe_token, upper_plan).to be_false
        expect(billing_profile.errors.messages).to include(:base)
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
        billing_profile.stub(:push_billing_profile_updated_message)
      end

      context "when Stripe token is present" do
        it "updates the card in Stripe" do
          @fake_stripe_customer.should_receive(:card=).with(stripe_token)
          billing_profile.update_subscription stripe_token, nil
        end

        it 'saves the updated card properties returned from Stripe' do
          billing_profile.update_subscription stripe_token, nil
          billing_profile.reload

          expect(billing_profile.stripe_id).to eq(stripe_id)
          expect(billing_profile.last_four).to eq(last4)
          expect(billing_profile.card_type).to eq(card_type)
          expect(billing_profile.exp_month).to eq(exp_month)
          expect(billing_profile.exp_year).to eq(exp_year)
        end

        it 'sends a push notification to the frontend' do
          billing_profile.should_receive(:push_billing_profile_updated_message)
          billing_profile.update_subscription stripe_token, nil
        end

        context 'when Stripe raises some card error' do
          before do
            @fake_stripe_customer.should_receive(:save).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})
          end

          it 'adds an error on billing profile base and return false' do
            expect(billing_profile.update_subscription stripe_token, upper_plan).to be_false
            expect(billing_profile.errors.messages).to include(:base)
          end

          it 'does not save the billing profile' do
            billing_profile.should_not_receive(:save)
            billing_profile.update_subscription stripe_token, upper_plan
          end

          it 'does not attempt to update the plan' do
            @fake_stripe_customer.should_not_receive(:update_subscription)
            billing_profile.update_subscription stripe_token, upper_plan
          end
        end

        context 'when Stripe raises some card declined error' do
          before do
            @fake_stripe_customer.should_receive(:save).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_declined', message: 'stripe error' }})
          end

          it 'adds an error on billing profile base and return false' do
            expect(billing_profile.update_subscription stripe_token, upper_plan).to be_false
            expect(billing_profile.errors.messages[:base][0]).to match /Try contacting your bank/
          end

          it 'does not save the billing profile' do
            billing_profile.should_not_receive(:save)
            billing_profile.update_subscription stripe_token, upper_plan
          end

          it 'does not attempt to update the plan' do
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

          it "changes user's Stripe subscription" do
            @fake_stripe_customer.should_receive(:update_subscription).with(plan: upper_plan.stripe_id)
            expect(billing_profile.update_subscription nil, upper_plan)
          end
        end

        context 'the new plan gives less n2o than what user is currently utitlizing' do
          before do
            user.update_attribute 'max_n2o', 200
            user.update_attribute 'used_n2o', 150
          end

          it "does not update user's Stripe subscription" do
            @fake_stripe_customer.should_not_receive(:update_subscription)
            expect(billing_profile.update_subscription nil, lower_plan)
          end

          it 'adds an error on billing profile and return false' do
            expect(billing_profile.update_subscription nil, lower_plan).to be_false
            expect(billing_profile.errors.messages).to include(:base)
          end
        end
      end
    end
  end

  describe '#push_billing_profile_updated_message' do
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }

    it 'pushes aio:billing_profile_updated notification' do
      expect(Shover).to receive(:publish).with(user.id, 'aio:billing_profile_updated', billing_profile.serialize_as_hash)

      channel = double('channel')
      Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
      channel.should_receive(:trigger).ordered.with('aio:billing_profile_updated', billing_profile.serialize_as_hash)

      billing_profile.push_billing_profile_updated_message
    end
  end

  describe '#deliver_card_updated_mail' do
    let!(:billing_profile) { create :billing_profile }

    it 'delivers card updated mail' do
      expect {
        billing_profile.deliver_card_updated_mail
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.first.handler.should =~ /'SubscriptionMailer'\nmethod_name: :credit_card_changed_alert\nargs:\n- #{billing_profile.id}\n/
    end
  end

  describe '.find_profiles_with_expiring_cards' do
    let!(:plan) { create :plan }

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

      it 'returns only active profiles expiring in the given month' do
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
