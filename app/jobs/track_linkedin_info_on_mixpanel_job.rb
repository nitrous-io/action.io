class TrackLinkedinInfoOnMixpanelJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find user_id
    linkedin_user = LinkedinUser.init(user)

    unless linkedin_user == LinkedinUser::NON_AUTHENTICATED_USER
      companies = linkedin_user.positions.all.map { |p| p['company'] }

      if(latest_company = companies.first)
        mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
        mixpanel.set user.email, 'linkedin_company_name'      => latest_company['name'],
                                 'linkedin_company_industry'  => latest_company['industry'],
                                 'linkedin_company_type'      => latest_company['type'],
                                 'linkedin_company_size'      => latest_company['size']
      end
    end
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(self.new(user_id))
  end
end

