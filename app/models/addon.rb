class Addon < ActiveRecord::Base
  extend EncryptedAttributes

  encrypted_attr_accessor :password, :sso_salt
  attr_accessor           :payload

  serialize :required_vars, JSON
  serialize :config_vars, JSON

  has_many    :addon_admins, dependent: :destroy
  has_many    :users, through: :addon_admins

  belongs_to  :owner, class_name: 'User'

  validates_presence_of   :owner, on: :create
  validates_presence_of   :uid, :config_vars,
                          :production_base_url, :production_sso_url,
                          :test_base_url, :test_sso_url,
                          :encrypted_password, :encrypted_password_iv,
                          :encrypted_sso_salt, :encrypted_sso_salt_iv,
                          :state

  validates_uniqueness_of :uid, :production_base_url, :production_sso_url,
                          :test_base_url, :test_sso_url

  before_create do
    users << owner if owner && !users.include?(owner)
  end

  # TODO: maybe change this to proper state machine
  scope :enabled, -> { where(state: "enabled") }

  def self.parse_manifest(manifest)
    addon = Addon.new

    begin
      parsed_manifest = ActiveSupport::JSON.decode(manifest)

      parsed_manifest['api'] ||= {}
      parsed_manifest['api']['production'] ||= {}
      parsed_manifest['api']['test'] ||= {}

      addon.uid = parsed_manifest['id']
      addon.password = parsed_manifest['api']['password']
      addon.sso_salt = parsed_manifest['api']['sso_salt']
      addon.production_base_url = parsed_manifest['api']['production']['base_url']
      addon.production_sso_url  = parsed_manifest['api']['production']['sso_url']
      addon.test_base_url = parsed_manifest['api']['test']['base_url']
      addon.test_sso_url  = parsed_manifest['api']['test']['sso_url']
      addon.config_vars = parsed_manifest['api']['config_vars']
      addon.required_vars = parsed_manifest['api']['required_vars']

    rescue MultiJson::DecodeError
      addon.errors.add(:payload, "cannot be parsed")
    end

    addon
  end
end
