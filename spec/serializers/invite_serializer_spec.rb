require 'spec_helper'

describe InviteSerializer do
  let!(:invite)    { create :invite }

  subject { invite.serialize_as_json }

  it 'has only id, email, state fields' do
    hash = JSON.parse(subject)['invite']
    hash.delete('id').should == invite.id
    hash.delete('box_id').should == invite.box_id
    hash.delete('email').should == invite.email
    hash.delete('state').should == invite.state
    hash.should be_empty
  end
end
