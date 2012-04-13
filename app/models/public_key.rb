class PublicKey < ActiveRecord::Base
  belongs_to :user
  attr_accessible :name, :key

  validates :user, presence: true
  validates :key,  presence: true

  validate :public_key_is_valid

  def public_key_is_valid
    unless SSHKey.valid_ssh_public_key?(key)
      errors.add :key, 'is not a valid SSH public key'
    end
  end
end
