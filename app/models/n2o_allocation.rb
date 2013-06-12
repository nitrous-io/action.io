class N2oAllocation < ActiveRecord::Base
  belongs_to :user
  belongs_to :resource, polymorphic: true

  scope :allocated, where(deallocated_at: nil)

  attr_accessible

  def deallocate!
    self.deallocated_at = Time.now
    save!
  end
end
