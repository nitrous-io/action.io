# helper methods for communicating with Freighter
# methods designed to be consistent with Coach class

class Freighter
  class FreighterError < RuntimeError; end

  PORT = 65333
  WEBHOOK_PATH = 'https://33.33.33.10:5000/freighter/webhook' # FIXME non-hardcoded
  DEFAULT_IMAGE = 'ubuntu-upstart:trusty'
  STATE_KEYVALUE_SEPARATOR = ':'
  STATE_KEYPAIR_SEPARATOR = ','

  attr_reader :box, :endpoint_host

  def initialize(box)
    @box = box
    @endpoint_host = box.boxhost.ip
  end

  def list
    self.class.get freighter_uri('/containers')
  end

  def provision_box(options={})
    return false unless @box.born? || @box.failed?

    @params = {
      name: self.box.name,
      image: DEFAULT_IMAGE,
      callback_url: WEBHOOK_PATH,
      state: state_param(op: 'provision'),
      'public_key[]' => self.box.public_keys
    }.merge(options)

    uri = freighter_uri('/containers')
    puts "Coach HTTP POST to #{uri} #{self.box.container_name}" unless Rails.env.test?
    result = client.post freighter_uri('/containers'), @params
    render(result)
  end

  def start_box(options={})
    container_operation(:start, options)
  end

  def stop_box(options={})
    container_operation(:stop, options)
  end

  def restart_box(options={})
    container_operation(:restart, options)
  end

  def terminate_box(options={})
    @params = {
      callback_url: WEBHOOK_PATH,
      state: state_param(op: 'terminate')
    }.merge(options)
    result = client.delete freighter_uri("/containers/#{box.container_uid}"), @params
    render(result)
  end

  def self.state_string_to_params(state)
    (state || '').split(STATE_KEYPAIR_SEPARATOR).inject({}.with_indifferent_access) do |h, keypair|
      k, v = keypair.split(STATE_KEYVALUE_SEPARATOR)
      h[k] = v
      h
    end
  end

  private

  def container_operation(operation, options={})
    raise "Invalid operation #{operation}" if !%i(start stop restart).include?(operation)
    options = remove_coach_options(options)
    @params = {
      callback_url: WEBHOOK_PATH,
      state: state_param(op: operation)
    }.merge(options)
    result = client.post(
      freighter_uri(['/containers', box.container_uid, operation].join('/')),
      @params
    )
    render(result)
  end

  # key 'op' (operation) should be in given options
  def state_param(options={})
    {
      box_id: self.box.id,
    }.merge(options).map do |k, v|
      [k, v].join(STATE_KEYVALUE_SEPARATOR)
    end.join(STATE_KEYPAIR_SEPARATOR)
  end

  def render(result)
    return true if (200..299).include?(result.code)
    raise FreighterError, "#{result.status}: Params: #{@params}"
  end

  def freighter_uri(path)
    host = [endpoint_host, PORT].join(':')
    "http://#{[host, path].join}"
  end

  # TODO temporary workaround for box state machine passing expected_specs_for_coach
  def remove_coach_options(options)
    stripped_options = options.dup
    box.expected_specs_for_coach.keys.each {|key| stripped_options.delete(key) }
    stripped_options
  end

  def client
    @http_client ||= HTTPClient.new
  end
end
