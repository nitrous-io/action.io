require 'spec_helper'

describe DefaultMessageVerifier do
  describe '.verifier' do
    it "returns a message verifier initialized with app's secret token and json as the serializer" do
      verifier = DefaultMessageVerifier.verifier
      expect(verifier).to be_instance_of ActiveSupport::MessageVerifier
      expect(verifier.instance_variable_get :@serializer).to equal JSON
      expect(verifier.instance_variable_get :@secret).to eq Rails.application.config.secret_token
    end
  end
end
