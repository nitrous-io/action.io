require 'spec_helper'

describe PublicKeySerializer do
  let!(:public_key) { create :public_key }

  subject { public_key.serialize_as_json }

  it 'has only id, user_id, name, and key fields' do
    hash = JSON.parse(subject)
    hash.delete('id'             ).should == public_key.id
    hash.delete('user_id'        ).should == public_key.user_id
    hash.delete('name'           ).should == public_key.name
    hash.delete('md5_fingerprint').should == public_key.md5_fingerprint
    hash.should be_empty
  end
end
