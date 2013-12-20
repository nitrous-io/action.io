require 'spec_helper'

describe ActionCipher do
  it 'can encrypt and decrypt data' do
    key = 'secret key'
    data = 'super secret data'
    base64 = /\A[a-zA-Z\d\+\/=]+\n?\z/

    iv, encrypted = ActionCipher.encrypt key, data
    expect(data).not_to eq(encrypted)
    expect(encrypted).to match base64
    expect(iv).to match base64

    iv2, encrypted2 = ActionCipher.encrypt key, data
    expect(data).not_to eq(encrypted2)
    expect(encrypted2).to match base64
    expect(iv2).to match base64

    expect(iv).not_to eq(iv2)
    expect(encrypted).not_to eq(encrypted2)

    decrypted = ActionCipher.decrypt key, iv, encrypted
    decrypted2 = ActionCipher.decrypt key, iv2, encrypted2

    expect(decrypted).to eq(data)
    expect(decrypted2).to eq(data)

    iv, encrypted = ActionCipher.encrypt key, 'top secret'
    expect(ActionCipher.decrypt(key, iv, encrypted)).to eq('top secret')
    expect {
      ActionCipher.decrypt 'wrong key', iv, encrypted
    }.to raise_error OpenSSL::Cipher::CipherError
  end
end

