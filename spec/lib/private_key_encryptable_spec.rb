require 'spec_helper'

class Encrypted
  include PrivateKeyEncryptable

  attr_accessor :encrypted_private_key, :encrypted_private_key_iv
end

describe PrivateKeyEncryptable do
  subject { Encrypted.new }

  describe '#aes_key' do
    it 'adds an empty aes_key' do
      expect(subject.aes_key).to eq ''
    end
  end

  describe '#private_key=' do
    it 'uses ActionCipher to encrypt the given key with the AES key' do
      key = 'unencrypted key'
      expect(ActionCipher).to receive(:encrypt).with(subject.aes_key, key)

      subject.private_key = key

      expect(subject.encrypted_private_key).not_to eq key
    end

    it 'sets the encrypted private key and initialization vector' do
      key = 'unencrypted key'
      expect(ActionCipher).to receive(:encrypt)
        .with(subject.aes_key, key)
        .and_return(['initialization vector', 'encrypted key'])

      subject.private_key = key

      expect(subject.encrypted_private_key).to eq 'encrypted key'
      expect(subject.encrypted_private_key_iv).to eq 'initialization vector'
    end
  end

  describe '#private_key' do
    it 'returns the decrypted private key' do
      key = 'unencrypted key'
      subject.private_key = key

      expect(subject.private_key).to eq key
    end
  end
end
