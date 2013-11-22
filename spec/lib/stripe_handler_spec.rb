require 'spec_helper'

describe StripeHandler do
  let!(:user) { create :user }
  let!(:plan) { create :subscription_plan }
  let!(:token) { '123456' }

  let!(:stripe_handler) { StripeHandler.new }

  describe "#add_customer" do
    context 'when both stripe token and plan is provided' do
      it 'creates a new customer in Stripe' do
        Stripe::Customer.should_receive(:create).with(
          email: user.email,
          description: "#{user.username} #{user.email}",
          card: token,
          plan: plan.stripe_id
        )

        stripe_handler.add_customer token: token, user: user, plan: plan
      end
    end

    context 'when stripe token is not provided' do
      it 'sets the error ivar and returns false' do
        expect(stripe_handler.add_customer({ token: nil, plan: plan, user: user })).to be_false
        expect(stripe_handler.error).to_not be_nil
      end
    end

    context 'when plan is not provided' do
      it 'sets the error ivar and returns false' do
        expect(stripe_handler.add_customer({ token: token, plan: nil, user: user })).to be_false
        expect(stripe_handler.error).to_not be_nil
      end
    end

    context 'when stripe raises some card error' do
      before do
        Stripe::Customer.should_receive(:create).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})
      end

      it 'sets the error ivar and returns false' do
        expect(stripe_handler.add_customer({ token: token, plan: plan, user: user })).to be_false
        expect(stripe_handler.error).to_not be_nil
      end
    end

    context 'when stripe raises card declined error' do
      before do
        Stripe::Customer.should_receive(:create).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_declined', message: 'stripe error' }})
      end

      it 'sets a custom message to the error ivar and returns false' do
        expect(stripe_handler.add_customer({ token: token, plan: plan, user: user })).to be_false
        expect(stripe_handler.error).to match /Try contacting your bank/
      end
    end
  end

  describe "#update_customer" do
    let!(:stripe_id) { 'stripe_id' }
    let!(:stripe_customer) { double() }

    context 'when the customer is found' do
      before do
        stripe_customer.stub(:card=)
        stripe_customer.stub(:save)
        stripe_customer.should_receive(:email=).with(user.email)
        stripe_customer.should_receive(:description=).with("#{user.username} #{user.email}")

        Stripe::Customer.should_receive(:retrieve).with(stripe_id).and_return stripe_customer
      end

      context 'when a stripe token is present' do
        it 'updates customer card' do
          stripe_customer.should_receive(:card=).with(token)
          stripe_handler.update_customer({ stripe_id: stripe_id, token: token, user: user })
        end
      end

      context 'when a stripe token is not present' do
        it 'dont update customer card' do
          stripe_customer.should_not_receive(:card=)
          stripe_handler.update_customer({ stripe_id: stripe_id, token: '', user: user })
        end
      end

      it 'returns the customer' do
        expect(stripe_handler.update_customer({ stripe_id: stripe_id, token: token, user: user })).to eq stripe_customer
      end

      context 'when stripe raises some card error when saving customer' do
        before do
          stripe_customer.should_receive(:save).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})
        end

        it 'sets the error ivar and returns false' do
          expect(stripe_handler.update_customer({ stripe_id: stripe_id, token: token, user: user })).to be_false
          expect(stripe_handler.error).to_not be_nil
        end
      end

      context 'when stripe raises card declined error when saving customer' do
        before do
          stripe_customer.should_receive(:save).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_declined', message: 'stripe error' }})
        end

        it 'sets a custom message to the error ivar and returns false' do
          expect(stripe_handler.update_customer({ stripe_id: stripe_id, token: token, user: user })).to be_false
          expect(stripe_handler.error).to match /Try contacting your bank/
        end
      end
    end

    context 'when the customer is not found' do
      before do
        Stripe::Customer.should_receive(:retrieve).with(stripe_id).and_return nil
      end

      it 'sets error ivar and returns false' do
          expect(stripe_handler.update_customer({ stripe_id: stripe_id, token: token, user: user })).to be_false
        expect(stripe_handler.error).to_not be_nil
      end
    end

    
  end

  describe "change_plan" do
    let!(:stripe_id) { 'stripe_id' }
    let!(:stripe_customer) { double() }

    context 'when the customer is found' do
      before do
        stripe_customer.stub(:update_subscription)

        Stripe::Customer.should_receive(:retrieve).with(stripe_id).and_return stripe_customer
      end

      it 'calls update subscription with the stripe id of the plan' do
        stripe_customer.should_receive(:update_subscription).with({ plan: plan.stripe_id })
        stripe_handler.change_plan({ plan: plan, stripe_id: stripe_id })
      end
    end

    context 'when the customer is not found' do
      before do
        Stripe::Customer.should_receive(:retrieve).with(stripe_id).and_return nil
      end

      it 'sets error ivar and returns false' do
        expect(stripe_handler.change_plan({ stripe_id: stripe_id, plan: plan })).to be_false
        expect(stripe_handler.error).to_not be_nil
      end
    end

  end

  describe "cancel_subscription" do
    let!(:stripe_id) { 'stripe_id' }
    let!(:stripe_customer) { double() }

    context 'when the customer is found' do
      before do
        stripe_customer.stub(:cancel_subscription)

        Stripe::Customer.should_receive(:retrieve).with(stripe_id).and_return stripe_customer
      end

      it 'calls cancel subscription on stripe customer' do
        stripe_customer.should_receive(:cancel_subscription)
        stripe_handler.cancel_subscription({ stripe_id: stripe_id })
      end
    end

    context 'when the customer is not found' do
      before do
        Stripe::Customer.should_receive(:retrieve).with(stripe_id).and_return nil
      end

      it 'sets error ivar and returns false' do
        expect(stripe_handler.cancel_subscription({ stripe_id: stripe_id })).to be_false
        expect(stripe_handler.error).to_not be_nil
      end
    end
  end
end
