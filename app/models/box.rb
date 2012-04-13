class Box < ActiveRecord::Base
  attr_accessible :name, :region

  has_many :box_admins, dependent: :destroy
  has_many :users, through: :box_admins
  belongs_to :box_template
  belongs_to :owner, class_name: 'User'

  validates_presence_of :owner, on: :create
  validates :name,   presence: true, uniqueness: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/, message: "Use a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }
  validates :region, presence: true, inclusion: { in: Settings.valid_regions }

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
    @boxer ||= Action::Boxer.new(owner.username, name, region)
  end

  state_machine :status, initial: :new do
    event(:provision) { transition :new       => :stopped    }
    event(:start)     { transition :stopped   => :running    }
    event(:suspend)   { transition :running   => :suspended  }
    event(:resume)    { transition :suspended => :running    }
    event(:stop)      { transition :running   => :stopped    }
    event(:terminate) { transition :stopped   => :terminated }

    before_transition on: :provision do |box|
      box_info = box.boxer.provision_box(box.box_template.image)
      box.host, box.port = box_info[:ip], box_info[:port]
      box.save!
    end

    before_transition on: :start do |box|
      box.boxer.start_box
    end

    before_transition on: :stop do |box|
      box.boxer.stop_box
    end

    before_transition on: :suspend do |box|
    end

    before_transition on: :resume do |box|
    end

    before_transition on: :terminate do |box|
      box.boxer.terminate_box
    end
  end
end
