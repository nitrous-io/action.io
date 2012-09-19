class Coach
  class CoachError < RuntimeError; end

  include HTTParty
  format  :json
  # TODO: Are we going to have different username/password for
  # coaches in different regions?
  basic_auth ENV['COACH_USERNAME'], ENV['COACH_PASSWORD']

  attr_reader :box, :coach_uri

  def initialize(box)
    @box = box
    @coach_uri = @box.region.coach_uri
  end

  def provision_box
    public_keys = @box.key_pairs.map(&:public_key)
    box_hash = {
      name: self.box.name,
      id: self.box.id,
      runtime: self.box.box_template.image,
      # This is hard-coded for now
      memory: 256,
      disk_space: 2048
    }

    if public_keys.present?
      box_hash.merge!(public_keys: ActiveSupport::JSON.encode(public_keys))
    end

    result = self.class.post "#{self.coach_uri}/boxes", query: { box: box_hash }

    render(result)
  end

  def start_box
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.name}/start",
                            query: { box: { boxer_id: self.box.host } }

    render(result)
  end

  def stop_box
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.name}/stop",
                            query: { box: { boxer_id: self.box.host } }

    render(result)
  end

  def terminate_box
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.name}/destroy",
                            query: { box: { boxer_id: self.box.host } }

    render(result)
  end

  def add_public_key(key)
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.name}",
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                data_type: 'aio:configure:add_public_key',
                                data: key
                              }
                            }
    render(result)
  end

  def remove_public_key(key)
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.name}",
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                data_type: 'aio:configure:remove_public_key',
                                data: key
                              }
                            }
    render(result)
  end

  private
  def render(result)
    if result['status'] == 'OK'
      return true
    else
      raise CoachError, "#{result['status']}: #{result['text']}"
    end
  end
end
