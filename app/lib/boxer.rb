require 'net/ssh'

class Boxer
  TEMPLATES_DIR = File.join(File.expand_path(File.dirname(__FILE__)), 'boxer', 'templates')

  DEFAULT_USER   = 'action'

  CONTAINER_TYPES = {
    'rails' => 'rails-container-template',
  }.freeze

  VALID_REGIONS = [
    'us-west-1',      # US West (N California)
    'us-west-2',      # US West (Oregon)
    'us-east-1',      # US East (Virginia)
    'eu-west-1',      # EU West (Ireland)
    'ap-southeast-1', # Asia Pacific (Singapore)
    'ap-northeast-1', # Asia Pacific (Japan)
    'sa-east-1'       # South America (Sao Paulo)
  ]

  REGION_TO_LXC_SNAPSHOT = {
    'us-west-1' => 'snap-f8c07d9e'
  }

  REGION_TO_VANILLA_AMI = {
    'us-east-1'       => 'ami-a29943cb',
    'us-west-1'       => 'ami-87712ac2',
    'us-west-2'       => 'ami-20800c10',
    'eu-west-1'       => 'ami-e1e8d395',
    'ap-southeast-1'  => 'ami-a4ca8df6',
    'ap-northeast-1'  => 'ami-60c77761',
    'sa-east-1'       => 'ami-8cd80691'
  }.freeze

  class MissingOptionError        < RuntimeError; end
  class InvalidRegionError        < RuntimeError; end
  class InvalidContainerTypeError < RuntimeError; end
  class BoxDoesNotExistError      < RuntimeError; end
  class AWSCredentialsAbsentError < RuntimeError; end

  attr_accessor :hostname, :region, :public_keys,
                :ec2_host, :ec2_key, :box_id, :user_ids,
                :box_key, :volume_id

  def initialize(options)
    self.hostname    = options[:hostname]
    self.region      = options[:region]
    self.public_keys = options[:public_keys]
    self.ec2_host    = options[:ec2_host]
    self.ec2_key     = options[:ec2_key]
    self.volume_id   = options[:volume_id]
    # Store these in /etc/actionio
    self.box_key     = options[:box_key]
    self.box_id      = options[:box_id]
    self.user_ids    = options[:user_ids]

    unless self.hostname && self.region && self.public_keys &&
           self.ec2_host && self.ec2_key && self.box_key && self.box_id && self.user_ids
      raise MissingOptionError
    end

    raise InvalidRegionError unless VALID_REGIONS.include? self.region
  end

  def provision_box(container_type)
    raise InvalidContainerTypeError if (container_template = CONTAINER_TYPES[container_type]).nil?
    ip, ssh_port, volume_id, block_device_id = nil, nil, nil, nil

    Net::SSH.start(self.ec2_host, 'ubuntu', key_data: [self.ec2_key], paranoid: false) do |ssh|
      # Fetch next available IP and two ports using a Redis transaction
      redis_output = ssh.exec!("echo -e 'MULTI\\nBRPOPLPUSH available_ips used_ips 1\\n" +
                               "BRPOPLPUSH available_ports used_ports 1\\n" +
                               "BRPOPLPUSH available_block_devices used_block_devices 1\\n" +
                               "EXEC' | redis-cli -p 65000 -x").strip

      matches = redis_output.scan(/\n\w?\d+/im)
      # We need two values from redis - one IP octet and one port
      if matches.size == 3
        ip = "192.168.254.#{matches[0].strip}"
        ssh_port = matches[1].strip
        block_device_id = matches[2].strip

        # Create a volume based on a snapshot (snapshot is per-region/availability-zone) (source ~/.eucarc first)
        # ...get the volume ID
        raw_volume_info = ssh.exec!("source ~/.eucarc; euca-create-volume -z $EC2_ZONE --snapshot #{REGION_TO_LXC_SNAPSHOT[self.region]}")
        volume_id = raw_volume_info.match(/(vol-\w+)\b/)[1]
        Rails.logger.debug("------> Volume ID: #{volume_id}")
        # Check if volume is available (loop until it is available)
        ssh.exec!("source ~/.eucarc; while euca-describe-volumes #{volume_id} | grep -v \"available\" ; do echo ''; done")
        Rails.logger.debug("------> Finished checking volume is available")
        # Attach volume (euca-attach-volume) to the device using a number
        ssh.exec!("source ~/.eucarc; euca-attach-volume #{volume_id} -i $EC2_INSTANCE -d sd#{block_device_id}")
        Rails.logger.debug("------> Finished attaching volume")
        # Check if volume is attached
        ssh.exec!("source ~/.eucarc; while euca-describe-volumes #{volume_id} | tail -n 1 | grep -v \"attached\" ; do echo ''; done")
        Rails.logger.debug("------> Finished checking if volume is attached")
        # Create the dir ready for you to mount
        ssh.exec!("sudo mkdir -p /var/lib/lxc/#{self.hostname}")
        Rails.logger.debug("------> Created dir")
        # Once is is attached, mount volume to local drive (/var/lib/lxc/#{host_name})
        mount_output = ssh.exec!("sudo mount /dev/xvd#{block_device_id} /var/lib/lxc/#{self.hostname}")
        Rails.logger.debug("------> Finished, mount_output -> #{mount_output}")
        # Replace rails-container-template with the hostname
        ssh.exec!("sudo sed -i \"s/rails-container-template/#{self.hostname}/g\" /var/lib/lxc/#{self.hostname}/config")
        # Also with the actual hostname
        ssh.exec!("sudo sh -c 'echo \"#{self.hostname}\" > /var/lib/lxc/#{self.hostname}/rootfs/etc/hostname'")

        # Add to fstab so that mount will be saved upon reboot
        # TODO
        # Configure IP
        ssh.exec!("sudo sh -c \"echo \\\"auto lo\niface lo inet loopback\n\nauto eth0\n" +
                  "iface eth0 inet static\n\  address #{ip}\n  " +
                  "netmask 255.255.255.0\n  gateway 192.168.254.1\\\"" +
                  " > /var/lib/lxc/#{self.hostname}/rootfs/etc/network/interfaces\"")
        # Make sure that container is started upon reboot
        ssh.exec!("sudo ln -s /var/lib/lxc/#{self.hostname}/config /etc/lxc/auto/#{self.hostname}.conf")
        # Set the TERM environment variable to xterm-256color in /etc/profile
        ssh.exec!("sudo sh -c \"echo \\\"\nexport TERM=xterm-256color\\\" >> /var/lib/lxc/#{self.hostname}/rootfs/etc/profile\"")
        # Create IP Tables for SSH
        ssh.exec!("sudo iptables -t nat -A PREROUTING -p tcp --dport #{ssh_port} -j DNAT --to #{ip}:22")

        self.public_keys.each do |pkey|
          ssh.exec!("sudo sh -c \"echo \\\"#{pkey}\\\" >> /var/lib/lxc/#{self.hostname}/rootfs/etc/ssh/univ_public_keys\"")
        end

        # Create /etc/actionio
        ssh.exec!("sudo mkdir -p /var/lib/lxc/#{self.hostname}/rootfs/etc/actionio")
        # Add box_key to /etc/actionio/box_key
        ssh.exec!("sudo sh -c 'echo \"#{self.box_key.to_s.strip}\" > /var/lib/lxc/#{self.hostname}/rootfs/etc/actionio/box_key'")
        # Add user_ids to /etc/actionio/users
        ssh.exec!("sudo sh -c 'echo \"#{self.user_ids.map(&:to_s).join("\\n").strip}\" > /var/lib/lxc/#{self.hostname}/rootfs/etc/actionio/users'")
        # Add box_id to /etc/actionio/box_id
        ssh.exec!("sudo sh -c 'echo \"#{self.box_id.to_s.strip}\" > /var/lib/lxc/#{self.hostname}/rootfs/etc/actionio/box_id'")
        # Add username to /etc/actionio/box_owner
        ssh.exec!("sudo sh -c 'echo \"#{DEFAULT_USER}\" > /var/lib/lxc/#{self.hostname}/rootfs/etc/actionio/box_owner'")
        # Add haproxy routing rules, one setting up the acl, the other setting up the backend proxying rule
        haproxy_acl_name = "is_#{self.hostname.gsub(/-/, '_')}"
        haproxy_acl_header = "acl #{haproxy_acl_name} hdr_beg(Host) -i #{self.hostname}."
        haproxy_acl_body = "use_backend #{self.hostname} if #{haproxy_acl_name}"
        haproxy_backend_body = "server box-server #{ip} weight 1 maxconn 1024"

        ssh.exec!("echo -e \"sed -i '/#pragma mark ACTION_ACL_MARKER/ a\\\\\\\\\\t#{haproxy_acl_header}\\\\\\n\\t#{haproxy_acl_body}' /etc/haproxy/haproxy.cfg\" | sudo bash")
        ssh.exec!("echo -e \"sed -i '/#pragma mark ACTION_BACKEND_MARKER/ a\\\\\\backend #{self.hostname}\\\\\\n\\t#{haproxy_backend_body}' /etc/haproxy/haproxy.cfg\" | sudo bash")
        # Restart HAProxy
        ssh.exec!("sudo /etc/init.d/haproxy reload")
      end
    end

    return { host: self.ec2_host, ssh_port: ssh_port, volume_id: volume_id, block_device_id: block_device_id }
  end

  def status
    # :terminated, :suspended, :ready, :frozen
    state = :terminated

    Net::SSH.start(self.ec2_host, 'ubuntu', key_data: [self.ec2_key], paranoid: false) do |ssh|
      result = ssh.exec!("sudo ls /var/lib/lxc/#{self.hostname}")
      if result !~ /No such file or directory/im
        running_state = result = ssh.exec!("sudo lxc-info -n #{self.hostname}")
        state = case
          when running_state =~ /RUNNING/ then :ready
          when running_state =~ /FROZEN/  then :frozen
          when running_state =~ /STOPPED/ then :shut_down
          else :terminated
        end
      end
    end

    return state
  end

  def terminate_box
    status = false

    raise MissingOptionError if self.volume_id.blank?

    Net::SSH.start(self.ec2_host, 'ubuntu', key_data: [self.ec2_key], paranoid: false) do |ssh|
      result = ssh.exec!("sudo ls /var/lib/lxc/#{self.hostname}")
      if result !~ /No such file or directory/im
        address_line = ssh.exec!("sudo grep 'address 192\.168\.254\.' /var/lib/lxc/#{self.hostname}/rootfs/etc/network/interfaces").strip

        if address_line.length > 0
          octet = address_line.match(/192.168.254.(\d+)/)[1]

          iptables_rule = ssh.exec!("sudo iptables -L PREROUTING -t nat --line-numbers | grep 192.168.254.#{octet}")
          matches = iptables_rule.scan(/^(\d+).*?dpt:(\d+)/)

          redis_to_exec = "MULTI\\n"
          ports_to_delete = []

          matches.each do |match|
            ports_to_delete << match[1]
            redis_to_exec << "LREM used_ports 0 #{match[1]}\\n"
            redis_to_exec << "RPUSH available_ports #{match[1]}\\n"
          end

          redis_to_exec << "LREM used_ips 0 #{octet}\\n"
          redis_to_exec << "RPUSH available_ips #{octet}\\n"
          redis_to_exec << "EXEC"

          # Only do destructive actions if two ports
          # are obtained from the grep
          if matches.count == 1
            ssh.exec!("sudo lxc-stop -n #{self.hostname}")

            o = ssh.exec!("sudo umount /var/lib/lxc/#{self.hostname}")
            Rails.logger.debug("Finished unmounting, output --> #{o}")

            o = ssh.exec!("source ~/.eucarc; euca-detach-volume #{self.volume_id}")
            Rails.logger.debug("Finished detaching, output --> #{o}")

            o = ssh.exec!("source ~/.eucarc; while euca-describe-volumes #{self.volume_id} | tail -n 1 | grep -v \"available\" ; do echo ''; done")
            Rails.logger.debug("Waiting for detach, output --> #{o}")

            o = ssh.exec!("source ~/.eucarc; euca-delete-volume #{self.volume_id}")
            Rails.logger.debug("Finished deleting: #{o}")

            o = ssh.exec!("sudo lxc-destroy -n #{self.hostname}")
            Rails.logger.debug("Finished destrying lxc -> #{o}")

            ports_to_delete.each do |port|
              iptables_rule = ssh.exec!("sudo iptables -L PREROUTING -t nat --line-numbers | grep dpt:#{port}")
              matcher = iptables_rule.match(/^(\d+)/)

              if !matcher.nil? && !(ipt_line_number = matcher[1]).nil?
                ssh.exec!("sudo iptables -D PREROUTING #{ipt_line_number} -t nat")
              end
            end

            ssh.exec!("echo -e '#{redis_to_exec}' | redis-cli -p 65000 -x")

            # Delete lines from haproxy
            ssh.exec!("sudo sed -i \"/#{self.hostname}\\|192\.168\.254\.#{octet}/d\" /etc/haproxy/haproxy.cfg")
            # Restart haproxy
            ssh.exec!("sudo /etc/init.d/haproxy reload")

            status = true
          end
        end
      end
    end

    return status
  end

  def shut_down_box
    status = false

    Net::SSH.start(self.ec2_host, 'ubuntu', key_data: [self.ec2_key], paranoid: false) do |ssh|
      result = ssh.exec!("sudo ls /var/lib/lxc/#{self.hostname}")
      if result !~ /No such file or directory/im
        ssh.exec!("sudo lxc-stop -n #{self.hostname}")
        status = true
      end
    end

    return status
  end

  def start_box
    status = false

    Net::SSH.start(self.ec2_host, 'ubuntu', key_data: [self.ec2_key], paranoid: false) do |ssh|
      result = ssh.exec!("sudo ls /var/lib/lxc/#{self.hostname}")
      if result !~ /No such file or directory/im
        ssh.exec!("sudo lxc-start -n #{self.hostname} -d")
        ssh.exec!("sudo lxc-wait -n #{self.hostname}")

        status = true
      end
    end

    return status
  end

  def freeze_box
    status = false

    Net::SSH.start(self.ec2_host, 'ubuntu', key_data: [self.ec2_key], paranoid: false) do |ssh|
      result = ssh.exec!("sudo ls /var/lib/lxc/#{self.hostname}")
      if result !~ /No such file or directory/im
        ssh.exec!("sudo lxc-freeze -n #{self.hostname}")
        status = true
      end
    end

    return status
  end

  def unfreeze_box
    status = false

    Net::SSH.start(self.ec2_host, 'ubuntu', key_data: [self.ec2_key], paranoid: false) do |ssh|
      result = ssh.exec!("sudo ls /var/lib/lxc/#{self.hostname}")
      if result !~ /No such file or directory/im
        ssh.exec!("sudo lxc-unfreeze -n #{self.hostname}")
        status = true
      end
    end

    return status
  end

  def add_key(public_key)
    status = false

    Net::SSH.start(self.ec2_host, 'ubuntu', key_data: [self.ec2_key], paranoid: false) do |ssh|
      result = ssh.exec!("sudo ls /var/lib/lxc/#{self.hostname}")
      if result !~ /No such file or directory/im
        ssh.exec!("sudo sh -c 'echo \"#{public_key}\" >> /var/lib/lxc/#{self.hostname}/rootfs/etc/ssh/univ_public_keys'")
        ssh.exec!("sudo chroot /var/lib/lxc/#{self.hostname}/rootfs chown -R #{DEFAULT_USER}:#{DEFAULT_USER} /etc/ssh/univ_public_keys")

        status = true
      end
    end

    return status
  end

  def delete_key(public_key)
    status = false

    Net::SSH.start(self.ec2_host, 'ubuntu', key_data: [self.ec2_key], paranoid: false) do |ssh|
      result = ssh.exec!("sudo ls /var/lib/lxc/#{self.hostname}")
      if result !~ /No such file or directory/im
        authorized_keys_file = "/var/lib/lxc/#{self.hostname}/rootfs/etc/ssh/univ_public_keys"

        result = ssh.exec!("sudo ls #{authorized_keys_file}")
        if result !~ /No such file or directory/im
          ssh.exec!("sudo sh -c 'sed -i \"s/#{public_key.gsub(/\//, '\/')}//g\" /var/lib/lxc/#{self.hostname}/rootfs/etc/ssh/univ_public_keys'")
          ssh.exec!("sudo chroot /var/lib/lxc/#{self.hostname}/rootfs chown -R #{DEFAULT_USER}:#{DEFAULT_USER} /etc/ssh/univ_public_keys")

          status = true
        end
      end
    end

    return status
  end

end
