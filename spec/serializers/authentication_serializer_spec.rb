require 'spec_helper'

describe AuthenticationSerializer do
  let!(:authentication) { create :authentication }

  subject { authentication.serialize_as_json }

  it 'has only id, user_id, provider, and uid fields' do
    hash = JSON.parse(subject)['authentication']
    expect(hash.delete('id'      )).to eq(authentication.id)
    expect(hash.delete('user_id' )).to eq(authentication.user_id)
    expect(hash.delete('provider')).to eq(authentication.provider)
    expect(hash.delete('uid'     )).to eq(authentication.uid)
    expect(hash).to be_empty
  end
end
