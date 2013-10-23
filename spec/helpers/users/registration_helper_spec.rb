require 'spec_helper'

describe Users::RegistrationsHelper do
  describe '.email_to_provider_website' do
    context 'when provider is known' do
      it 'returns the website url' do
        expect(email_to_provider_website 'hello@gmail.com').to eq 'https://www.gmail.com/'
        expect(email_to_provider_website 'iuse@hotmail.com').to eq 'https://www.outlook.com/'
        expect(email_to_provider_website 'blah@me.com').to eq 'https://www.icloud.com/'
      end
    end

    context 'when provider is unknown' do
      it 'returns nil' do
        expect(email_to_provider_website 'hello@aklsdj.com').to be_nil
      end
    end
  end
end
