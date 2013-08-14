class PapertrailEventParser
  def self.parse!(payload)
    parsed_payload = JSON.parse(payload)

    parsed_payload['events'].each do |event|
      # get full notation instead of scientific notation
      event_id = ("%f" % event['id'].to_s).to_i.to_s
      event_received_at = DateTime.parse(event['received_at'])

      message = event['message']
      matcher = message.match(/as a result of limit of \/lxc\/.*?-(\d+)/)

      if matcher && (box_id = matcher[1])
        box = Box.find(box_id)

        box.box_limit_hit_events.create(
          kind:            BoxLimitHitEvent::MEMORY,
          logged_event_id: event_id,
          limit_hit_at:    event_received_at
        )
      end
    end
  end

end
