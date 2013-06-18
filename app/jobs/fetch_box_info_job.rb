class FetchBoxInfoJob < Job
  attr_accessor :box_id
  attr_accessor :user_id

  def initialize(box_id, user_id)
    self.box_id = box_id
    self.user_id = user_id
  end

  def perform
    user = User.find user_id
    box = user.owned_boxes.find box_id

    box.coach.fetch_box_info
  end
end

