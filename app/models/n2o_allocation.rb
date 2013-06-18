class N2oAllocation < ActiveRecord::Base
  N2O_128MB_MEMORY  = 'n2o_128mb_memory'.freeze
  N2O_250MB_STORAGE = 'n2o_250mb_storage'.freeze

  module Kind
    BOX_CREATION = 0 # memory & storage
  end

  belongs_to :user
  belongs_to :resource, polymorphic: true

  scope :allocated, where(deallocated_at: nil)
  scope :deallocated, where('deallocated_at IS NOT NULL')

  attr_accessible

  after_save do
    user.update_balance!
  end

  def deallocated?
    deallocated_at.present?
  end

  def deallocate!
    self.deallocated_at = Time.now unless deallocated?
    save!
  end
end
