require 'spec_helper'

describe ActionUserAgentParser do
  it 'can parse a user agent from an Action.IO desktop client' do
    source = ActionUserAgentParser.parse('ActionIO/0.1.0 (Mac OS X; 10.8.2 12C2034; en_US) action-mac/febb16e')

    expect(source[:client]).to eq('ActionIO')
    expect(source[:version]).to eq('0.1.0')
    expect(source[:git]).to eql('action-mac/febb16e')
    expect(source[:os_name]).to eql('Mac OS X')
    expect(source[:os_version]).to eql('10.8.2')
    expect(source[:os_version_long]).to eql('10.8.2 12C2034')
    expect(source[:locale]).to eql('en_US')
  end
end
