require 'spec_helper'

describe ApplicationController do
  controller do
    def index
      render nothing: true
    end
  end

  describe '#ember_split_alternatives' do
    before do
      FakeFS.activate!
      FileUtils.mkdir_p(File.dirname(Settings.split_alternatives_config))
    end

    after do
      FakeFS.deactivate!
    end

    context 'when alternatives are present for the controller/action combination' do
      before do
        File.open(Settings.split_alternatives_config, 'w') do |f|
          f.puts """
ember:
  test:
    AIO.PlanView:
      - index_v1
      - index_v2
    AIO.BonusView:
      - index_v1
      - index_v2
"""
        end
      end

      it 'returns the alternatives' do
        get :index
        expect(controller.send(:ember_split_alternatives)).to eql({ 'AIO.PlanView' => ['index_v1', 'index_v2'], 'AIO.BonusView' => ['index_v1', 'index_v2'] })
      end
    end
  end

  describe '#rails_split_alternatives' do
    before do
      FakeFS.activate!
      FileUtils.mkdir_p(File.dirname(Settings.split_alternatives_config))
    end

    after do
      FakeFS.deactivate!
    end

    context 'when alternatives are present for the controller/action combination' do
      before do
        File.open(Settings.split_alternatives_config, 'w') do |f|
          f.puts """
rails:
  test:
    anonymous:
      index:
        - index_v1
        - index_v2
"""
        end
      end

      it 'returns the alternatives' do
        get :index
        expect(controller.send(:rails_split_alternatives)).to eql ['index_v1', 'index_v2']
      end
    end

    context 'when alternatives are not present for the controller/action combination' do
      before do
        File.open(Settings.split_alternatives_config, 'w') do |f|
          f.puts """
rails:
  test:
    anonymous:
      show:
        - index_v1
        - index_v2
"""
        end
      end

      it 'returns the alternatives' do
        get :index
        expect(controller.send(:rails_split_alternatives)).to eql []
      end
    end
  end

  describe '#authenticate_user!' do
    context 'when the user is authenticated' do
      let(:user) { create :external_authenticated_user }
      before { sign_in user }

      context 'when the user is not allowed to login' do
        it 'redirects to a confirmation controller' do
          get :index
          expect(controller).to redirect_to(new_confirmation_path)
        end
      end
    end
  end

  describe '#oauth_token_present?' do
    context 'when access_token param is present' do
      before { get :index, access_token: 'some_token' }

      it 'returns true' do
        expect(controller.send :oauth_token_present?).to be_truthy
      end
    end

    context 'when bearer_token param is present' do
      before { get :index, bearer_token: 'some_token' }

      it 'returns true' do
        expect(controller.send :oauth_token_present?).to be_truthy
      end
    end

    context 'when authorization header with content "Bearer <token>" is present' do
      before do
        request.env['HTTP_AUTHORIZATION'] = 'Bearer SomeOAuthToken'
        get :index
      end

      it 'returns true' do
        expect(controller.send :oauth_token_present?).to be_truthy
      end
    end

    context 'else' do
      before { get :index }

      it 'returns false' do
        expect(controller.send :oauth_token_present?).to be_falsey
      end
    end
  end
end
