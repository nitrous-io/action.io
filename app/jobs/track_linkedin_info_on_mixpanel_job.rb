class TrackLinkedinInfoOnMixpanelJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find user_id
    linkedin_user = LinkedinUser.init(user)

    unless linkedin_user == LinkedinUser::NON_AUTHENTICATED_USER
      positions = linkedin_user.positions.all
      return if positions.blank?

      if (company = positions.first['company'])
        mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
        mixpanel.set user.email, 'linkedin_company_name'      => company['name'],
                                 'linkedin_company_industry'  => company['industry'],
                                 'linkedin_company_type'      => company['type'],
                                 'linkedin_company_size'      => company['size']
      end
    end
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(self.new(user_id))
  end
end

