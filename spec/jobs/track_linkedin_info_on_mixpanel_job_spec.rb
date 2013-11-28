require 'spec_helper'

describe TrackLinkedinInfoOnMixpanelJob do
  describe '#perform' do
    let!(:user)             { create :user }
    let!(:mixpanel)         { double('mixpanel') }
    let!(:linkedin_user)    { double('lnkd_user') }

    before do
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
      LinkedinUser.stub(:init).and_return(linkedin_user)
    end

    context "LinkedIn user does not have any companies associated with his profile" do
      before do
        linkedin_user.stub_chain(:positions, :all).and_return []
      end

      it "should not call Mixpanel" do
        mixpanel.should_not_receive :set
        TrackLinkedinInfoOnMixpanelJob.new(user.id).perform
      end
    end

    context "LinkedIn user has companies associated with his profile" do
      before do
        linkedin_user.stub_chain(:positions, :all).and_return([
          { 'company' =>
            { 'name' => 'Nitrous.IO',
              'industry' => 'Computer Software',
              'type' => 'Privately Held',
              'size' => '0 - 5 employees'
            }
          },
          { 'company' =>
            {
              'name' => 'Apple Inc',
              'industry' => 'Computer Software',
              'type' => 'Publicly Held',
              'size' => '1000 - 2000 employees'
            }
          }
        ])
      end

      it "should call the Mixpanel API with the information about the user's current Linkedin company" do
        mixpanel.should_receive(:set).with user.email, 'linkedin_company_name'      => 'Nitrous.IO',
                                                       'linkedin_company_industry'  => 'Computer Software',
                                                       'linkedin_company_size'      => '0 - 5 employees',
                                                       'linkedin_company_type'      => 'Privately Held'
        TrackLinkedinInfoOnMixpanelJob.new(user.id).perform
      end
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user }

    it "should submit a delayed job" do
      expect {
        TrackLinkedinInfoOnMixpanelJob.submit_job(user.id)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match(/TrackLinkedinInfoOnMixpanelJob.*?user_id: #{user.id}/m)
    end
  end
end


