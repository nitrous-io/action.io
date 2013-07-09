class MacAppUpdate < ActiveRecord::Base
  attr_accessible :version, :title, :release_notes, :url, :file_size, :published

  validates_presence_of :version, :title, :release_notes, :url, :file_size

  validate :ensure_file_size_is_set

  scope :published, -> { where('published_at IS NOT NULL').order('published_at DESC') }

  def self.latest_url
    published.first.try(:url)
  end

  def published
    self.published_at.present?
  end

  def published=(published)
    published = ActiveRecord::ConnectionAdapters::Column.value_to_boolean published
    if published && self.published_at.blank?
      self.published_at = Time.zone.now
    elsif !published
      self.published_at = nil
    end
  end

  def ensure_file_size_is_set
    if self.published_at.present? && (self.file_size.blank? || self.file_size == 0)
      errors.add :file_size, 'needs to be set'
    end
  end

  def release_notes_in_html
    Maruku.new(self.release_notes).to_html
  end
end
