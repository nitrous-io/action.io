class ReadDefaultPublicKeyJob < Struct.new(:box_id)
  def perform
    box = Box.find self.box_id
    public_key = ReadDefaultPublicKey.run box
    message = ActiveSupport::JSON.encode box: { id: box.id, public_key: public_key }
    channel = Pusher["private-user-#{box.owner.id}"]

    channel.trigger 'aio:read_default_public_key', message
  end
end
