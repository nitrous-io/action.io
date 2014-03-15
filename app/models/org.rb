class Org < ActiveRecord::Base
  validates_presence_of :name, :permalink, :billing_email

  # Place validation errors for permalink on name because
  validate do
    errors.add :name, 'has already been taken' unless Org.find_by_permalink(permalized_name).nil?
  end

  before_validation do
    if self.permalink.blank?
      self.permalink = permalized_name
    end
  end

  protected
  def permalized_name
    self.name.to_s.downcase.gsub(/\W+/, ' ').squeeze.strip.gsub(/ /, '-')
  end
end
