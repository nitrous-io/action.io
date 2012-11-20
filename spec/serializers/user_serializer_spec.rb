require 'spec_helper'

describe UserSerializer do
  let!(:authentication) { create :authentication }
  let!(:user) { create :user, authentications: [authentication], available_invites: 10 }

  subject { user.serialize_as_json }

  it 'has id, username, email, full_name, available_invites and authentications fields' do
    hash = JSON.parse(subject)['user']
    hash.delete('id'       ).should == user.id
    hash.delete('username' ).should == user.username
    hash.delete('email'    ).should == user.email
    hash.delete('full_name').should == user.full_name
    hash.delete('available_invites').should eq(user.available_invites)
    hash.delete('authentications').should ==
      [JSON.parse(authentication.serialize_as_json)['authentication']]
    hash.should be_empty
  end
end
