class Box < ActiveRecord::Base
  attr_accessible :name

  has_many :box_admins, dependent: :destroy
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
  end

  after_create do
    Resque.enqueue(ProvisionBoxJob, self.id)
  end

  def boxer
    @boxer ||= Action::Boxer.new(username: owner.username,
                                 hostname: name,
                                 region: region.name,
                                 public_keys: owner.public_keys.pluck(:key),
                                 ec2_host: region.box_hosts.first.host,
                                 ec2_key: region.keypair)
  end

  state_machine initial: :new do
    event(:provision)         { transition :new          => :stopped      }

    event(:enqueue_start)     { transition :stopped      => :starting     }
    event(:start)             { transition :starting     => :running      }

    event(:enqueue_suspend)   { transition :running      => :suspending   }
    event(:suspend)           { transition :suspending   => :suspended    }

    event(:enqueue_resume)    { transition :suspended    => :resuming     }
    event(:resume)            { transition :resuming     => :running      }

    event(:enqueue_stop)      { transition :running      => :stopping     }
    event(:stop)              { transition :stopping     => :stopped      }

    event(:enqueue_terminate) { transition :stopped      => :terminating  }
    event(:terminate)         { transition :terminating  => :terminated   }

    before_transition(on: :provision) do |box|
      box_info = box.boxer.provision_box(box.box_template.image)
      box.host, box.port = box_info[:ip], box_info[:port]
      box.save!
    end

    before_transition(on: :enqueue_start)     { |box| Resque.enqueue(StartBoxJob,     box.id) }
    #before_transition(on: :enqueue_suspend)   { |box| Resque.enqueue(SuspendBoxJob,   box.id) }
    #before_transition(on: :enqueue_resume)    { |box| Resque.enqueue(ResumeBoxJob,    box.id) }
    before_transition(on: :enqueue_stop)      { |box| Resque.enqueue(StopBoxJob,      box.id) }
    before_transition(on: :enqueue_terminate) { |box| Resque.enqueue(TerminateBoxJob, box.id) }

    before_transition(on: :start)     { |box| box.boxer.start_box }
    #before_transition(on: :suspend)   { |box| }
    #before_transition(on: :resume)    { |box| }
    before_transition(on: :stop)      { |box| box.boxer.stop_box }
    before_transition(on: :terminate) { |box| box.boxer.terminate_box }
  end
end
