class PublicKey < ActiveRecord::Base
  belongs_to :user
  attr_accessible :name, :key

  validates :user_id, presence: true
  validates :key,     presence: true, uniqueness: { scope: :user_id, message: 'already exists' }

  validate :public_key_is_valid

  before_validation do
    key.strip! if key
  end

  before_save do
    self.name = comment_fragment if name.blank?
  end

  def self.enqueue_import_github_keys(user)
    Resque.enqueue ImportGitHubKeysJob, user.id
  end

  def self.import_github_keys(user)
    return unless github_access_token = user.token_for('github')
    response = HTTParty.get 'https://api.github.com/user/keys', headers: {
      'Authorization' => "token #{github_access_token}"
    }
    if response.code != 200
      raise "Failed: #{response.headers['status']} #{response.response.body}"
    end
    response.parsed_response.each { |hash| user.public_keys.create name: hash['title'], key: hash['key'] }
    Pusher["private-user-#{user.id}"].trigger('aio:public_keys_updated', user.public_keys.reload.as_json)
  end

  def public_key_is_valid
    unless SSHKey.valid_ssh_public_key?(key)
      errors.add :key, 'is not a valid SSH public key'
    end
  end

  def key_fragment
    key[/\A\s*ssh-(rsa|dss)\s+([a-zA-Z0-9\+\/=]+)/,2] if key
  end

  def comment_fragment
    key[/\A\s*ssh-(rsa|dss)\s+\S+\s+(\S+)/,2] if key
  end

  def md5_fingerprint
    Digest::MD5.hexdigest(Base64.decode64(key_fragment)).gsub(/(.{2})(?=.)/, '\1:\2') if key_fragment
  end

  def as_json(options=nil, override=false)
    options = (options || {}).merge(methods: 'md5_fingerprint') unless override
    super(options)
  end
end
