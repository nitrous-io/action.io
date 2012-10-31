require 'spec_helper'

describe ActionCipher do
  it 'can encrypt and decrypt data' do
    key = 'secret key'
    data = 'super secret data'
    base64 = /\A[a-zA-Z\d\+\/=]+\n?\z/

    iv, encrypted = ActionCipher.encrypt key, data
    data.should_not == encrypted
    encrypted.should match base64
    iv.should match base64

    iv2, encrypted2 = ActionCipher.encrypt key, data
    data.should_not == encrypted2
    encrypted2.should match base64
    iv2.should match base64

    iv.should_not == iv2
    encrypted.should_not == encrypted2

    decrypted = ActionCipher.decrypt key, iv, encrypted
    decrypted2 = ActionCipher.decrypt key, iv2, encrypted2

    decrypted.should == data
    decrypted2.should == data

    iv, encrypted = ActionCipher.encrypt key, 'top secret'
    ActionCipher.decrypt(key, iv, encrypted).should == 'top secret'
    expect {
      ActionCipher.decrypt 'wrong key', iv, encrypted
    }.to raise_error OpenSSL::Cipher::CipherError
  end
end

