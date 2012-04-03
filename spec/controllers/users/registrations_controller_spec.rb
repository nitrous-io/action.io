require 'spec_helper'

describe Users::RegistrationsController do
  it 'is a subclass of Devise::RegistrationsController' do
    Devise::RegistrationsController.subclasses.should include Users::RegistrationsController
  end

  before { request.env["devise.mapping"] = Devise.mappings[:user] }

  describe '#clear_omniauth' do
    before { session['devise.omniauth_hash'] = { foo: 'bar' } }

    context 'when omniauth param is not 1' do
      it 'clears omniauth hash in session' do
        get :new
        session['devise.omniauth_hash'].should be_blank
      end
    end

    context 'when omniauth param is 1' do
      it 'preserves omniauth hash in session' do
        get :new, omniauth: '1'
        session['devise.omniauth_hash'].should be_present
      end
    end

    describe 'POST create' do
      it 'also calls clear_omniauth' do
        controller.should_receive :clear_omniauth
        post :create
      end
    end
  end
end

