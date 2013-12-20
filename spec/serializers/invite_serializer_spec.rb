require 'spec_helper'

describe InviteSerializer do
  let!(:invite)   { create :invite }
  let!(:n2o_fill) { create :n2o_fill, resource: invite, amount: 20 }

  subject { invite.serialize_as_json }

  it 'has only id, email, state, and created_at fields' do
    hash = JSON.parse(subject)['invite']
    expect(hash.delete('id'        )).to eq(invite.id)
    expect(hash.delete('email'     )).to eq(invite.email)
    expect(hash.delete('state'     )).to eq(invite.state)
    expect(hash.delete('created_at')).to eq(invite.created_at.as_json)
    expect(hash.delete('n2o_earned')).to eq(20)
    expect(hash).to be_empty
  end
end
