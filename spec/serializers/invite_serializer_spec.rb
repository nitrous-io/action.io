require 'spec_helper'

describe InviteSerializer do
  let!(:invite)   { create :invite }
  let!(:n2o_fill) { create :n2o_fill, resource: invite, amount: 20 }

  subject { invite.serialize_as_json }

  it 'has only id, email, state, and created_at fields' do
    hash = JSON.parse(subject)['invite']
    hash.delete('id'        ).should == invite.id
    hash.delete('email'     ).should == invite.email
    hash.delete('state'     ).should == invite.state
    hash.delete('created_at').should eq(invite.created_at.as_json)
    hash.delete('n2o_earned').should == 20
    hash.should be_empty
  end
end
