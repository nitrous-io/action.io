require 'spec_helper'

describe PublicKeySerializer do
  let!(:public_key) { create :public_key }

  subject { public_key.serialize_as_json }

  it 'has only id, user_id, name, and key fields' do
    hash = JSON.parse(subject)['public_key']
    expect(hash.delete('id'             )).to eq(public_key.id)
    expect(hash.delete('user_id'        )).to eq(public_key.user_id)
    expect(hash.delete('name'           )).to eq(public_key.name)
    expect(hash.delete('md5_fingerprint')).to eq(public_key.md5_fingerprint)
    expect(hash).to be_empty
  end
end
