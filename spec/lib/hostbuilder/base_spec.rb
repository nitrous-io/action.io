require 'spec_helper'

describe Hostbuilder::Base do
  describe 'constructor' do
    it 'assigns its first argument to @boxhost' do
      hostbuilder = Hostbuilder::Base.new('first-arg')
      expect(hostbuilder.boxhost).to eq 'first-arg'
    end
  end

  describe '#apt_username' do
    let!(:boxhost) { create :dedicated_boxhost }
    let!(:hostbuilder) { Hostbuilder::Base.new(boxhost) }

    context 'when boxhost has no owner' do
      before { boxhost.owner = nil }

      it 'returns nil' do
        expect(hostbuilder.apt_username).to be_nil
      end
    end

    context 'when boxhost has an owner' do
      let!(:user) { create :user }
      before { boxhost.owner = user }

      it 'returns the username of its owner' do
        expect(hostbuilder.apt_username).to eq user.username
      end
    end
  end

  describe '#apt_password' do
    let!(:boxhost) { create :dedicated_boxhost }
    let!(:hostbuilder) { Hostbuilder::Base.new(boxhost) }
    let!(:apt_repo_app) { Doorkeeper::Application.create name: 'apt.nitrous.io', redirect_uri: 'http://example.com' }

    context 'when boxhost has no owner' do
      before { boxhost.owner = nil }

      it 'returns nil' do
        expect(hostbuilder.apt_password).to be_nil
      end
    end

    context 'when boxhost has an owner' do
      let!(:user) { create :user }
      before { boxhost.owner = user }

      context 'when apt repo oauth token for the owner does not exist' do
        it 'creates and returns an oauth token' do
          expect {
            password = hostbuilder.apt_password
          }.to change { Doorkeeper::AccessToken.count }.by(1)

          token = Doorkeeper::AccessToken.last
          expect(token.resource_owner_id).to eq user.id
          expect(token.application).to eq apt_repo_app
          expect(token.scopes.to_s).to eq 'user'

          expect(hostbuilder.apt_password).to eq token.token
        end
      end

      context 'when apt repo oauth token for the owner exists' do
        let!(:token) { Doorkeeper::AccessToken.create(resource_owner_id: user.id, application_id: apt_repo_app.id, scopes: 'user') }

        it 'returns the existing oauth token' do
          expect(hostbuilder.apt_password).to eq token.token
        end
      end
    end
  end
end
