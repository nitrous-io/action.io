require 'spec_helper'

describe FetchUserCompanyJob do
  let!(:user) { create :user, id: 69 }
  let(:channel) { double.as_null_object }

  before { User.stub(:find).with(user.id) { user } }

  describe '#perform' do

    context 'when the user has a company specified in his GitHub profile' do
      before do
        linkedin_user = double('LinkedinUser')
        LinkedinUser.stub(:new).with(user) { linkedin_user }
        linkedin_user.stub(:has_company?) { false }

        github_user = double('GithubUser')
        GithubUser.stub(:new).with(user) { github_user }
        github_user.should_receive(:has_company?) { true }
      end

      it 'should send a true message via Pusher' do
        expect(Pusher).to receive(:[]).with('private-user-69') { channel }
        expect(channel).to receive(:trigger) do |message, has_company|
          message.should == 'aio:fetch_user_company'
          has_company.should == true
        end

        FetchUserCompanyJob.new(69).perform
      end
    end

    context 'when the user has a company specified in his LinkedIn profile' do
      before do
        github_user = double('GithubUser')
        GithubUser.stub(:new).with(user) { github_user }
        github_user.should_receive(:has_company?) { false }

        linkedin_user = double('LinkedinUser')
        LinkedinUser.stub(:new).with(user) { linkedin_user }
        linkedin_user.stub(:has_company?) { true }
      end

      it 'should send a true message via Pusher' do
        expect(Pusher).to receive(:[]).with('private-user-69') { channel }
        expect(channel).to receive(:trigger) do |message, has_company|
          message.should == 'aio:fetch_user_company'
          has_company.should == true
        end

        FetchUserCompanyJob.new(69).perform
      end
    end

    context 'when the user does not have a company specified in both his GitHub and LinkedIn profiles' do
      before do
        github_user = double('GithubUser')
        GithubUser.stub(:new).with(user) { github_user }
        github_user.should_receive(:has_company?) { false }

        linkedin_user = double('LinkedinUser')
        LinkedinUser.stub(:new).with(user) { linkedin_user }
        linkedin_user.stub(:has_company?) { false }
      end

      it 'should send a false message via Pusher' do
        expect(Pusher).to receive(:[]).with('private-user-69') { channel }
        expect(channel).to receive(:trigger) do |message, has_company|
          message.should == 'aio:fetch_user_company'
          has_company.should == false
        end

        FetchUserCompanyJob.new(69).perform
      end
    end
  end
end
