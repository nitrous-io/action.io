class Shover
  class << self
    def publish(user_id, event, data)
      user_id = user_id.kind_of?(User) ? user_id.id : user_id
      HTTParty.post(Settings.shover_server_uri + '/publish', body: {
        p: DefaultMessageVerifier.verifier.generate([user_id, event, data])
      }, timeout: 5)
    end

    def broadcast(event, data)
      HTTParty.post(Settings.shover_server_uri + '/broadcast', body: {
        p: DefaultMessageVerifier.verifier.generate([event, data])
      }, timeout: 5)
    end
  end
end
