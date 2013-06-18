require 'spec_helper'

describe UserSerializer do
  let!(:authentication) { create :authentication }
  let!(:user) { create :user, authentications: [authentication], available_invites: 10, max_n2o: 10, used_n2o: 20, intro_seen: true, confirmed_at: Time.now }

  context 'when scope is the same user' do
    subject { user.serialize_as_json scope: user }

    it 'has users fields' do
      hash = JSON.parse(subject)['user']
      hash.delete('id').should == user.id
      hash.delete('admin').should == user.admin
      hash.delete('username').should == user.username
      hash.delete('email').should == user.email
      hash.delete('full_name').should == user.full_name
      hash.delete('available_invites').should eq user.available_invites
      hash.delete('max_n2o').should eq user.max_n2o
      hash.delete('used_n2o').should eq user.used_n2o
      hash.delete('intro_seen').should eq user.intro_seen
      hash.delete('created_at').should eq user.created_at.as_json
      hash.delete('confirmed_at').should eq user.confirmed_at.as_json
      hash.delete('authentications').should ==
        [JSON.parse(authentication.serialize_as_json)['authentication']]
      hash.should be_empty
    end
  end

  context 'when scope is a different user' do
    let(:other_user) { create :user }

    subject { user.serialize_as_json scope: other_user }

    it 'has id, username, full_name, and created_at' do
      hash = JSON.parse(subject)['user']
      hash.delete('id'       ).should == user.id
      hash.delete('username' ).should == user.username
      hash.delete('full_name').should == user.full_name
      hash.delete('created_at').should eq(user.created_at.as_json)
      hash.should be_empty
    end
  end

  context 'when scope is not provided' do
    subject { user.serialize_as_json }

    it 'has id, username, full_name, and created_at' do
      hash = JSON.parse(subject)['user']
      hash.delete('id'       ).should == user.id
      hash.delete('username' ).should == user.username
      hash.delete('full_name').should == user.full_name
      hash.delete('created_at').should eq(user.created_at.as_json)
      hash.should be_empty
    end
  end
end
