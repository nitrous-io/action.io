require 'spec_helper'

describe CollaborationInviteSerializer do
  let!(:invite) { create :collaboration_invite }

  subject { invite.serialize_as_json }

  it 'has only id, email, state, and box_id fields' do
    hash = JSON.parse(subject)['collaboration_invite']
    hash.delete('id'    ).should == invite.id
    hash.delete('email' ).should == invite.email
    hash.delete('state' ).should == invite.state
    hash.delete('box_id').should == invite.box_id
    hash.should be_empty
  end
end
