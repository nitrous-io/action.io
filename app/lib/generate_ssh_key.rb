module GenerateSSHKey
  def self.generate
    SSHKey.generate type: 'RSA', bits: 2048
  end
end
