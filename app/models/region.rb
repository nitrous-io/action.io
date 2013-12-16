class Region < ActiveRecord::Base
  attr_accessible :name, :description, :coach_uri, :box_server_uri, :version

  has_many :boxes, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates_presence_of :description

  scope :enabled, -> { where(enabled: true).order(:id) }

  state_machine initial: :up do
    event(:start_to_go_down)      { transition  :up                  => :going_down             }
    event(:go_up)                 { transition  [:going_down, :down] => :up                     }
    event(:go_down)               { transition  :going_down          => :down                   }

    event(:disable_box_creation)  { transition :up                    => :box_creation_disabled }
    event(:enable_box_creation)   { transition :box_creation_disabled => :up                    }

    after_transition do: :push_maintainence_state_message
  end

  def push_maintainence_state_message
    payload = { region_id: self.id, state: self.state }
    Shover.broadcast 'aio:region_status', payload
    Pusher["maintenance-channel"].trigger('aio:region_status', payload)
  end

  def can_create_boxes?
    self.enabled? && self.up?
  end

  # Parameters:
  # * options:
  #   * :country: ISO 3166-1 two-letter country code.
  #   * :continent: Two-letter continent code, e.g. NA, SA, EU, AF, AS, OC.
  #   * :region: ISO 3166-2 region code.
  def self.recommended_for(options={})
    country = options[:country]
    continent = options[:continent]
    state = options[:state]

    region_name = AwsRegion.for_state(country: country, state: state)
    region_name ||= AwsRegion.for_country(country)
    region_name ||= AwsRegion.for_continent(continent)
    return nil if region_name.blank?

    region = Region.where(name: region_name).first
    return nil if !region || !region.can_create_boxes?

    region
  end

end
