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
    # if the box is already in the middle of provisioning, then don't do anything
    return false unless @box.born? || @box.failed?

    box_hash = {
      name: self.box.name,
      id: self.box.id,
      cpu_shares: self.box.cpu_multiplier * Box::BASE_CPU_SHARES,
      memory: "#{self.box.memory}M",
      virtual_memory: "#{self.box.virtual_memory}M",
      disk_space: "#{self.box.storage}M",
      premium: self.box.premium?,
      public_keys: self.box.public_keys.to_json
    }

    if self.box.source_snapshot
      box_hash[:snapshot_id] = self.box.source_snapshot.id
      box_hash[:snapshot_url] = self.box.source_snapshot.url
    else
      box_hash[:runtime] = self.box.box_template.runtime
    end

    uri = "#{self.coach_uri}/boxes"
    puts "Coach HTTP POST to #{uri} #{self.box.container_name}" unless Rails.env.test?

    result = self.class.post uri, query: { box: box_hash }

    render(result)
  end

  def start_box(options={})
    # if the box is already in the middle of starting up, then don't do anything
    return false unless @box.stopped? || @box.provisioning?

    uri = "#{self.coach_uri}/boxes/#{self.box.container_name}/start"
    puts "Coach HTTP PUT to #{uri}" unless Rails.env.test?

    data = parse_box_specs(options)
    result = self.class.put uri,
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                public_keys: self.box.public_keys,
                                data: data.to_json
                              }
                            },
                            headers: { 'Content-Length' => '0' }

    render(result)
  end

  def stop_box
    return false unless @box.running?

    uri = "#{self.coach_uri}/boxes/#{self.box.container_name}/stop"
    puts "Coach HTTP PUT to #{uri}" unless Rails.env.test?

    result = self.class.put uri,
                            query: { box: { boxer_id: self.box.host } },
                            headers: { 'Content-Length' => '0' }

    render(result)
  end

  def restart_box(options={})
    return false unless @box.running?

    uri = "#{self.coach_uri}/boxes/#{self.box.container_name}/restart"
    puts "Coach HTTP PUT to #{uri}" unless Rails.env.test?

    data = parse_box_specs(options)
    result = self.class.put uri,
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                data: data.to_json
                              }
                            },
                            headers: { 'Content-Length' => '0' }

    render(result)
  end

  def terminate_box
    return false unless @box.stopped?

    uri = "#{self.coach_uri}/boxes/#{self.box.container_name}/destroy"
    puts "Coach HTTP PUT to #{uri}" unless Rails.env.test?

    result = self.class.put uri,
                            query: { box: { boxer_id: self.box.host } },
                            headers: { 'Content-Length' => '0' }

    render(result)
  end

  def snapshot_box(snapshot)
    uri = "#{self.coach_uri}/boxes/#{self.box.container_name}/snapshot"
    puts "Coach HTTP PUT to #{uri}" unless Rails.env.test?

    result = self.class.put uri,
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                snapshot_id: snapshot.id
                              }
                            },
                            headers: { 'Content-Length' => '0' }

    render(result)
  end

  def delete_snapshot(snapshot)
    uri = "#{self.coach_uri}/snapshots/#{snapshot.id}/destroy"
    puts "Coach HTTP PUT to #{uri}" unless Rails.env.test?

    result = self.class.put uri,
                            query: {
                              box: { boxer_id: self.box.host },
                              snapshot_url: snapshot.url
                            },
                            headers: { 'Content-Length' => '0' }
    render(result)
  end

  def clone_repo(repo_url)
    uri = "#{self.coach_uri}/boxes/#{@box.container_name}/clone_repo"
    puts "Coach HTTP PUT to #{uri} #{self.box.container_name}" unless Rails.env.test?

    box_hash = {
      boxer_id: self.box.host,
      repository_url: repo_url,
    }
    result = self.class.put uri, query: { box: box_hash }, headers: { 'Content-Length' => '0' }
    render(result)
  end

  def add_public_key(key)
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.container_name}",
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                data_type: 'aio:configure:add_public_key',
                                data: key
                              }
                            },
                            headers: { 'Content-Length' => '0' }

    render(result)
  end

  def remove_public_key(key)
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.container_name}",
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                data_type: 'aio:configure:remove_public_key',
                                data: key
                              }
                            },
                            headers: { 'Content-Length' => '0' }
    render(result)
  end

  def reconfigure(options={})
    data = parse_box_specs(options)
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.container_name}",
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                data_type: 'aio:configure:change_specs',
                                data: data.to_json
                              }
                            },
                            headers: { 'Content-Length' => '0' }
    render(result)
  end

  def update_auth
    data = {
      auth_username: self.box.auth_username,
      auth_password: self.box.auth_password
    }
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.container_name}",
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                data_type: 'aio:configure:update_auth',
                                data: data.to_json
                              }
                            },
          headers: { 'content-length' => '0' }
    render(result)
  end

  def update_custom_domain
    data = {
      custom_domain: self.box.custom_domain
    }
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.container_name}",
             query: {
               box: {
                 boxer_id: self.box.host,
                 data_type: 'aio:configure:update_custom_domain',
                 data: data.to_json
               }
             },
             headers: { 'content-length' => '0' }
    render(result)
  end

  def update_premium
    data = {
      premium: self.box.premium?
    }
    result = self.class.put "#{self.coach_uri}/boxes/#{self.box.container_name}",
                            query: {
                              box: {
                                boxer_id: self.box.host,
                                data_type: 'aio:configure:update_premium',
                                data: data.to_json
                              }
                            },
                            headers: { 'Content-Length' => '0' }
    render(result)
  end

  def fetch_box_info
    result = self.class.get "#{self.coach_uri}/boxes/#{self.box.container_name}",
                            query: {
                              box: {
                                boxer_id: self.box.host,
                              }
                            },
                            headers: { 'Content-Length' => '0' }

    render(result)
  end

  def migrate
    box_hash = {
      id: self.box.id,
      boxer_id: self.box.host,
    }
    uri = "#{self.coach_uri}/boxes/#{@box.container_name}/migrate"
    puts "Coach HTTP PUT to #{uri} #{self.box.container_name}" unless Rails.env.test?
    result = self.class.put uri, query: { box: box_hash }
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

  def parse_box_specs(options={})
    memory = options[:memory] || 256
    disk_space = options[:disk_space] || 750
    virtual_memory = options[:virtual_memory] || memory
    cpu_shares = options[:cpu_shares] || 512

    {
      memory: "#{memory}M",
      diskSpace: "#{disk_space}M",
      virtualMemory: "#{virtual_memory}M",
      cpuShares: cpu_shares
    }
  end
end
