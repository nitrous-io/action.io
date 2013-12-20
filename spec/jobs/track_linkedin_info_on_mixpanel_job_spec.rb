require 'spec_helper'

describe TrackLinkedinInfoOnMixpanelJob do
  describe '#perform' do
    let!(:user)          { create :user }
    let!(:mixpanel)      { instance_double('Mixpanel::Tracker') }
    let!(:linkedin_user) { instance_double('LinkedinUserd') }

    before do
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
      LinkedinUser.stub(:new).and_return(linkedin_user)
    end

    context 'when LinkedIn user does not have any positions associated with his profile' do
      before { linkedin_user.stub(:positions).and_return([]) }

      it 'should not call Mixpanel' do
        expect(mixpanel).not_to receive(:set)
        TrackLinkedinInfoOnMixpanelJob.new(user.id).perform
      end
    end

    context "LinkedIn user has positions associated with his profile" do
      before do
        linkedin_user.stub(:positions).and_return([
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

      it "should call the Mixpanel API with the information about the user's most recent LinkedIn company" do
        expect(mixpanel).to receive(:set).with user.email,  'linkedin_company_name'      => 'Nitrous.IO',
                                                            'linkedin_company_industry'  => 'Computer Software',
                                                            'linkedin_company_size'      => '0 - 5 employees',
                                                            'linkedin_company_type'      => 'Privately Held'
        TrackLinkedinInfoOnMixpanelJob.new(user.id).perform
      end
    end
  end

  describe '.submit_job' do
    let!(:user) { create :user }

    it 'should submit a delayed job' do
      expect {
        TrackLinkedinInfoOnMixpanelJob.submit_job(user.id)
      }.to change(Delayed::Job, :count).by(1)

      expect(Delayed::Job.last.handler).to match(/TrackLinkedinInfoOnMixpanelJob.*?user_id: #{user.id}/m)
    end
  end
end


