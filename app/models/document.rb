class Document < ActiveRecord::Base
  attr_accessible :pathname, :content, :last_saved_content

  belongs_to :user
  belongs_to :box

  validates :pathname,
    uniqueness: {
      scope: [:user_id, :box_id],
      message: 'should not contain duplicated document'
    },
    presence: true

  def self.opened(box_id, user_id)
    where(box_id: box_id, user_id: user_id)
  end
end
