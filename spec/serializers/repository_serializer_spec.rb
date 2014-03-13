require 'spec_helper'

describe Repository do
  let!(:repository) { create :repository }

  subject { repository.serialize_as_json }

  it 'has only the fields we expect it to have' do
    hash = JSON.parse(subject)['repository']
    expect(hash.delete('id')).to eq(repository.id)
    expect(hash.delete('box_id')).to eq(repository.box_id)
    expect(hash.delete('name')).to eq(repository.name)
    expect(hash.delete('full_name')).to eq(repository.full_name)
    expect(hash.delete('clone_url')).to eq(repository.clone_url)
    expect(hash.delete('state')).to eq(repository.state)
    expect(hash.delete('private')).to eq(repository.private)
    expect(hash.delete('cloned_at')).to eq(repository.cloned_at.as_json)
    expect(hash.delete('created_at')).to eq(repository.created_at.as_json)
    expect(hash).to be_empty
  end
end
