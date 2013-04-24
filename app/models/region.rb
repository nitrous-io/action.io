class Region < ActiveRecord::Base
  attr_accessible :name, :description, :coach_uri, :box_server_uri

  has_many :boxes, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates_presence_of :description

  scope :enabled, where(enabled: true).order(:id)

  state_machine initial: :up do
    event(:start_to_go_down)      { transition  :up                  => :going_down             }
    event(:go_up)                 { transition  [:going_down, :down] => :up                     }
    event(:go_down)               { transition  :going_down          => :down                   }

    event(:disable_box_creation)  { transition :up                    => :box_creation_disabled }
    event(:enable_box_creation)   { transition :box_creation_disabled => :up                    }

    after_transition do: :push_maintainence_state_message
  end

  def push_maintainence_state_message
    Pusher["maintenance-channel"].trigger('aio:region_status', { region_id: self.id, state: self.state })
  end

  def can_create_boxes?
    self.enabled? && self.up?
  end

end
