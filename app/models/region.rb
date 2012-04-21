class Region < ActiveRecord::Base
  attr_accessible :name, :description, :ami, :keypair

  has_many :box_hosts, dependent: :destroy
  has_many :boxes, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates_presence_of :description, :ami, :keypair

  def as_json(options=nil, override=false)
    options = (options || {}).merge(only: [
      'id',
      'name',
      'description'
    ]) unless override
    super(options)
  end
end
