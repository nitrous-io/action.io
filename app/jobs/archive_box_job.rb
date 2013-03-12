class ArchiveBoxJob < Struct.new(:box_id)
  def perform
    box = Box.find self.box_id
    box.coach.archive_box
  end
end
