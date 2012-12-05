class Document < ActiveRecord::Base
  belongs_to :user, dependent: :destroy
  belongs_to :box, dependent: :destroy

  validates :path,
    uniqueness: {
      scope: [:user_id, :box_id],
      message: 'should not contain duplicated document'
    },
    presence: true

  def self.opened(box_id, user_id)
    where(box_id: box_id, user_id: user_id)
  end
end
