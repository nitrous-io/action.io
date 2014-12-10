class ReadDefaultPublicKeyJob < Job
  attr_accessor :box_id
  attr_accessor :user_id

  def initialize(box_id, user_id)
    self.box_id = box_id
    self.user_id = user_id
  end

  def perform
    box = Box.running.find_by_id box_id
    return if !box

    public_key = ReadDefaultPublicKey.run box
    Rails.logger.error("Unable to read default public key for box #{box.id}") if !public_key

    payload = { box: { id: box_id, public_key: public_key } }

    Shover.publish user_id, 'aio:read_default_public_key', payload
    Pusher["private-user-#{user_id}"].trigger 'aio:read_default_public_key', payload.to_json
  end
end
