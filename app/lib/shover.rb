class Shover
  class ArgumentError < StandardError; end

  class << self
    def publish(user_id, event, data)
      raise ArgumentError, 'data must be hash!' unless data.is_a? Hash
      timestamp = Time.now.to_i
      begin
        post_publish user_id, event, data, timestamp
      rescue
        ShoverJob.submit_job user_id, event, data, timestamp
      end
    end

    def broadcast(event, data)
      raise ArgumentError, 'data must be hash!' unless data.is_a? Hash
      timestamp = Time.now.to_i
      begin
        post_broadcast event, data, timestamp
      rescue
        ShoverJob.submit_job nil, event, data, timestamp
      end
    end

    def post_publish(user_id, event, data, timestamp)
      user_id = user_id.kind_of?(User) ? user_id.id : user_id
      data.merge! _t: timestamp
      HTTParty.post(Settings.shover_server_uri + '/publish', body: {
        p: DefaultMessageVerifier.verifier.generate([user_id, event, data])
      }, timeout: 5)
    end

    def post_broadcast(event, data, timestamp)
      data.merge! _t: timestamp
      HTTParty.post(Settings.shover_server_uri + '/broadcast', body: {
        p: DefaultMessageVerifier.verifier.generate([event, data])
      }, timeout: 5)
    end
  end
end
