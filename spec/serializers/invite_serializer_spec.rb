require 'spec_helper'

describe InviteSerializer do
  let!(:invite) { create :invite }

  subject { invite.serialize_as_json }

  it 'has only id, email, state, and created_at fields' do
    hash = JSON.parse(subject)['invite']
    hash.delete('id'        ).should == invite.id
    hash.delete('email'     ).should == invite.email
    hash.delete('state'     ).should == invite.state
    hash.delete('created_at').should eq(invite.created_at.as_json)
    hash.should be_empty
  end
end
