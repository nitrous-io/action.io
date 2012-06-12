require 'spec_helper'

describe UserSerializer do
  let!(:authentication) { create :authentication }
  let!(:user) { create :user, authentications: [authentication] }

  subject { user.serialize_as_json }

  it 'has id, username, email, full_name, and authentications fields' do
    hash = JSON.parse(subject)
    hash.delete('id'       ).should == user.id
    hash.delete('username' ).should == user.username
    hash.delete('email'    ).should == user.email
    hash.delete('full_name').should == user.full_name
    hash.delete('authentications').should ==
      [JSON.parse(authentication.serialize_as_json)]
    hash.should be_empty
  end
end
