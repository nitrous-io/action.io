require 'spec_helper'

describe CollaborationInviteSerializer do
  let!(:invite) { create :collaboration_invite }

  subject { invite.serialize_as_json }

  it 'has only id, email, state, and box_id fields' do
    hash = JSON.parse(subject)['collaboration_invite']
    expect(hash.delete('id'    )).to eq(invite.id)
    expect(hash.delete('email' )).to eq(invite.email)
    expect(hash.delete('state' )).to eq(invite.state)
    expect(hash.delete('box_id')).to eq(invite.box_id)
    expect(hash).to be_empty
  end
end
