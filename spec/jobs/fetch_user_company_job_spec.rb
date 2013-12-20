require 'spec_helper'

describe FetchUserCompanyJob do
  let!(:user) { create :user, id: 69 }
  let(:channel) { double.as_null_object }

  before { User.stub(:find).with(user.id) { user } }

  describe '#perform' do

    context 'when the user has a company specified in his GitHub profile' do
      before do
        linkedin_user = instance_double('LinkedinUser')
        LinkedinUser.stub(:new).with(user) { linkedin_user }
        linkedin_user.stub(:has_company?) { false }

        github_user = instance_double('GithubUser')
        GithubUser.stub(:new).with(user) { github_user }
        expect(github_user).to receive(:has_company?) { true }
      end

      it 'should send a true message via Pusher' do
        expect(Shover).to receive(:publish).with(69, 'aio:fetch_user_company', {r: true})
        expect(Pusher).to receive(:[]).with('private-user-69') { channel }
        expect(channel).to receive(:trigger) do |message, payload|
          expect(message).to eq('aio:fetch_user_company')
          expect(payload).to eq({ r: true })
        end

        FetchUserCompanyJob.new(69).perform
      end
    end

    context 'when the user has a company specified in his LinkedIn profile' do
      before do
        github_user = instance_double('GithubUser')
        GithubUser.stub(:new).with(user) { github_user }
        expect(github_user).to receive(:has_company?) { false }

        linkedin_user = instance_double('LinkedinUser')
        LinkedinUser.stub(:new).with(user) { linkedin_user }
        linkedin_user.stub(:has_company?) { true }
      end

      it 'should send a true message via Pusher' do
        expect(Shover).to receive(:publish).with(69, 'aio:fetch_user_company', {r: true})
        expect(Pusher).to receive(:[]).with('private-user-69') { channel }
        expect(channel).to receive(:trigger) do |message, payload|
          expect(message).to eq('aio:fetch_user_company')
          expect(payload).to eq({ r: true })
        end

        FetchUserCompanyJob.new(69).perform
      end
    end

    context 'when the user does not have a company specified in both his GitHub and LinkedIn profiles' do
      before do
        github_user = instance_double('GithubUser')
        GithubUser.stub(:new).with(user) { github_user }
        expect(github_user).to receive(:has_company?) { false }

        linkedin_user = instance_double('LinkedinUser')
        LinkedinUser.stub(:new).with(user) { linkedin_user }
        linkedin_user.stub(:has_company?) { false }
      end

      it 'should send a false message via Pusher' do
        expect(Shover).to receive(:publish).with(69, 'aio:fetch_user_company', {r: false})
        expect(Pusher).to receive(:[]).with('private-user-69') { channel }
        expect(channel).to receive(:trigger) do |message, payload|
          expect(message).to eq('aio:fetch_user_company')
          expect(payload).to eq({ r: false })
        end

        FetchUserCompanyJob.new(69).perform
      end
    end
  end

  describe '.submit_job' do
    it "should submit a delayed job to fetch a user's company" do
      expect {
        FetchUserCompanyJob.submit_job(123)
      }.to change(Delayed::Job, :count).by(1)

      expect(Delayed::Job.last.handler).to match(/FetchUserCompanyJob/)
      expect(Delayed::Job.last.handler).to match(/user_id: 123/)
    end
  end
end
