require 'spec_helper'

describe Snapshot do
  let!(:snapshot) { create :snapshot }

  subject { snapshot.serialize_as_json }

  it 'has only the fields we expect it to have' do
    hash = JSON.parse(subject)['snapshot']
    expect(hash.delete('id')).to eq(snapshot.id)
    expect(hash.delete('name')).to eq(snapshot.name)
    expect(hash.delete('user_id')).to eq(snapshot.user_id)
    expect(hash.delete('box_id')).to eq(snapshot.box_id)
    expect(hash.delete('state')).to eq(snapshot.state)
    expect(hash.delete('created_at')).to eq(snapshot.created_at.as_json)
    expect(hash).to be_empty
  end
end
