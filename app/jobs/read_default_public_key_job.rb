class ReadDefaultPublicKeyJob < Job
  attr_accessor :box_id
  attr_accessor :user_id

  def initialize(box_id, user_id)
    self.box_id = box_id
    self.user_id = user_id
  end

  def perform
    box = Box.find box_id
    public_key = ReadDefaultPublicKey.run box

    channel = Pusher["private-user-#{user_id}"]
    channel.trigger 'aio:read_default_public_key', { box: { id: box_id, public_key: public_key } }.to_json
  end
end
