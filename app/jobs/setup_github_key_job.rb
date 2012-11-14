class SetupGithubKeyJob < Struct.new(:box_id)
  def perform
    box = Box.find self.box_id
    SetupGithubKey.setup box
  end
end
