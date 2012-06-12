require 'spec_helper'

describe AuthenticationSerializer do
  let!(:authentication) { create :authentication }

  subject { authentication.serialize_as_json }

  it 'has only id, user_id, provider, and uid fields' do
    hash = JSON.parse(subject)
    hash.delete('id'      ).should == authentication.id
    hash.delete('user_id' ).should == authentication.user_id
    hash.delete('provider').should == authentication.provider
    hash.delete('uid'     ).should == authentication.uid
    hash.should be_empty
  end
end
