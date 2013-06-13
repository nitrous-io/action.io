class N2oAllocation < ActiveRecord::Base
  N2O_BOX_CREATION  = 'n2o_box_creation'.freeze
  N2O_128MB_MEMORY  = 'n2o_128mb_memory'.freeze
  N2O_250MB_STORAGE = 'n2o_250mb_storage'.freeze

  module Kind
    BOX_CREATION = 0
  end

  belongs_to :user
  belongs_to :resource, polymorphic: true

  scope :allocated, where(deallocated_at: nil)

  attr_accessible

  def deallocate!
    self.deallocated_at = Time.now
    save!
  end
end
