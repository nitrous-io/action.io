class Box < ActiveRecord::Base
  attr_accessible :name

  has_many :box_admins, dependent: :destroy
  has_many :key_pairs,  dependent: :destroy

  has_many :users, through: :box_admins
  belongs_to :box_template
  belongs_to :owner, class_name: 'User'
  belongs_to :region

  validates_presence_of :owner, on: :create
  validates :name,      presence: true, uniqueness: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/, message: "Use a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }
  validates :region_id, presence: true

  before_save do
    name.downcase!
  end

  before_create do
    users << owner if owner && !users.include?(owner)
    generate_key
  end

  after_create do
    Resque.enqueue(ProvisionBoxJob, self.id)
  end

  def boxer
    @boxer ||= Action::Boxer.new(hostname: name,
                                 region: region.name,
                                 public_keys: owner.public_keys.pluck(:key),
                                 ec2_host: region.box_hosts.first.host,
                                 ec2_key: region.keypair,
                                 box_id: id,
                                 box_key: key,
                                 user_ids: users.pluck('users.id'))
  end

  def push_box_updated_message
    users.pluck('users.id').each do |user_id|
      Pusher["private-user-#{user_id}"].trigger('aio:box_updated', self.as_json)
    end
  end

  def as_json(options=nil, override=false)
    options = (options || {}).merge(except: 'key') unless override
    super(options)
  end

  state_machine initial: :provisioning do
    event(:provision)         { transition  :provisioning           => :stopped     }

    event(:enqueue_start)     { transition  :stopped                => :starting    }
    event(:start)             { transition [:stopped, :starting]    => :running     }

    event(:enqueue_suspend)   { transition  :running                => :suspending  }
    event(:suspend)           { transition [:running, :suspending]  => :suspended   }

    event(:enqueue_resume)    { transition  :suspended              => :resuming    }
    event(:resume)            { transition [:suspended, :resuming]  => :running     }

    event(:enqueue_stop)      { transition  :running                => :stopping    }
    event(:stop)              { transition [:running, :stopping]    => :stopped     }

    event(:enqueue_terminate) { transition  :stopped                => :terminating }
    event(:terminate)         { transition [:stopped, :terminating] => :terminated  }

    before_transition(on: :provision) do |box|
      box_info = box.boxer.provision_box(box.box_template.image)
      key = box.generate_key_pair

      box.boxer.add_public_key(key.public_key)

      box.host = box_info[:host]
      box.port = box_info[:ssh_port]
      box.tty_port = box_info[:tty_port]
      box.save!
    end

    before_transition(on: :enqueue_start)     { |box| Resque.enqueue(StartBoxJob,     box.id) }
    before_transition(on: :enqueue_suspend)   { |box| Resque.enqueue(SuspendBoxJob,   box.id) }
    before_transition(on: :enqueue_resume)    { |box| Resque.enqueue(ResumeBoxJob,    box.id) }
    before_transition(on: :enqueue_stop)      { |box| Resque.enqueue(StopBoxJob,      box.id) }
    before_transition(on: :enqueue_terminate) { |box| Resque.enqueue(TerminateBoxJob, box.id) }

    before_transition(on: :start)     { |box| box.boxer.start_box     }
    before_transition(on: :suspend)   { |box| box.boxer.freeze_box    }
    before_transition(on: :resume)    { |box| box.boxer.unfreeze_box  }
    before_transition(on: :stop)      { |box| box.boxer.shut_down_box }
    before_transition(on: :terminate) { |box| box.boxer.terminate_box }

    after_transition do: :push_box_updated_message
  end

  def add_public_key(key_string)
    boxer.add_key(key_string)
  end

  def remove_public_key(key_string)
    boxer.delete_key(key_string)
  end

  def generate_key_pair
    key = SSHKey.generate(type: "RSA", bits: 2048)
    self.key_pairs.create!(public_key: key.ssh_public_key, private_key: key.private_key)
  end

  private
  def generate_key
    self.key = SecureRandom.base64(24)
  end
end
