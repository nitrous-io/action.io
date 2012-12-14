require 'spec_helper'

class CurrentUserFromDoorkeeperTokenTest
  include CurrentUserFromDoorkeeperToken

  def doorkeeper_token
    nil
  end
end

describe CurrentUserFromDoorkeeperToken do
  subject do
    CurrentUserFromDoorkeeperTokenTest.new
  end

  describe '#current_user' do
    context 'when doorkeeper_token returns nil' do
      its(:current_user) { should be_nil }
    end

    context 'when doorkeeper_token exists' do
      context 'when resource owner exists' do
        let(:user) { create :user }

        before do
          subject.stub(:doorkeeper_token) { double resource_owner_id: user.id }
        end

        its(:current_user) { should eq user }
      end

      context 'when resource owner does not exist' do
        before do
          subject.stub(:doorkeeper_token) { double resource_owner_id: 9001 }
        end

        it 'raises error' do
          expect {
            subject.current_user
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
