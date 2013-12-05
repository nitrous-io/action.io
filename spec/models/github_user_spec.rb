require 'spec_helper'

describe GithubUser do
  let!(:user) { create :user }

  describe '#initialize' do
    it 'sets the user' do
      GithubUser.new(user).user.should == user
    end

    it 'sets a default value of nil for user' do
      GithubUser.new.user.should == nil
    end
  end

  describe '#client' do
    it 'returns nil if user is not present' do
      github_user = GithubUser.new

      github_user.client.should be_nil
    end

    it 'returns nil if user does not have a token for GitHub' do
      user.stub(:token_for).with(:github) { nil }
      github_user = GithubUser.new(user)

      github_user.client.should be_nil
    end

    context 'when user has a GitHub token' do
      let(:octokit_client) { double('Octokit::Client') }

      before do
        user.stub(:token_for).with(:github) { 'wtf' }
        Octokit::Client.stub(:new).with(access_token: 'wtf') { octokit_client }
      end

      it "creates a new Octokit::Client with the user's GitHub token" do
        octokit_client.stub(:login)

        github_user = GithubUser.new(user)
        client = github_user.client

        expect(Octokit::Client).to have_received(:new).with(access_token: 'wtf')
      end

      context 'when we get an Octokit::Unauthorized error when we try to login' do
        before { octokit_client.stub(:login).and_raise(Octokit::Unauthorized) }

        it 'returns nil' do
          github_user = GithubUser.new(user)
          github_user.client.should be_nil
        end
      end

      context 'when we can login' do
        before { octokit_client.stub(:login) { 'defunkt' } }

        it 'returns a new Octokit::Client' do
          github_user = GithubUser.new(user)
          github_user.client.should == octokit_client
        end
      end
    end
  end

  describe '#authenticated?' do
    let(:user) { create :user }
    let(:github_user) { GithubUser.new(user) }

    context 'when there is no client' do
      before { github_user.stub(:client) { nil } }

      it 'returns false' do
        github_user.authenticated?.should == false
      end
    end

    context 'when there is a client (i.e. user can be authenticated with GitHub)' do
      let(:client) { double('Octokit::Client') }

      before { github_user.stub(:client) { client } }

      it 'returns true' do
        github_user.authenticated?.should == true
      end
    end
  end

  describe '#has_company?' do
    let(:user) { create :user }
    let(:github_user) { GithubUser.new(user) }

    it 'returns false if user is not present' do
      GithubUser.new.has_company?.should == false
    end

    context 'when there is no client' do
      before { github_user.stub(:client) { nil } }

      it 'returns false' do
        github_user.has_company?.should == false
      end
    end

    context 'when there is a client (i.e. user can be authenticated with GitHub)' do
      let(:client) { double('Octokit::Client') }
      let(:profile) { double('Octokit::Client#user') }

      before do
        github_user.stub(:client) { client }
        client.stub(:user) { profile }
      end

      context 'and has a company in their profile' do
        before { profile.stub(:company) { 'Nutritious.IO' } }

        it 'returns true' do
          github_user.has_company?.should == true
        end
      end

      context 'and does not have a company in their profile' do
        before { profile.stub(:company) { nil } }

        it 'returns false' do
          github_user.has_company?.should == false
        end
      end
    end
  end

  describe '#profile' do
    let(:user) { create :user }
    let(:github_user) { GithubUser.new(user) }

    it 'returns nil if user is not present' do
      GithubUser.new.profile.should be_nil
    end

    context 'when there is no client' do
      before { github_user.stub(:client) { nil } }

      it 'returns nil' do
        github_user.profile.should be_nil
      end
    end

    context 'when there is a client (i.e. user can be authenticated with GitHub)' do
      let(:client) { double('Octokit::Client') }

      before { github_user.stub(:client) { client } }

      it 'returns the user from Octokit::Client' do
        profile = double
        client.should_receive(:user) { profile }

        github_user.profile.should == profile
      end
    end
  end

  describe '#add_key' do
    it 'delegates to the client' do
      github_user = GithubUser.new(user)
      client = double('Octokit::Client').as_null_object
      github_user.stub(:client) { client }

      github_user.add_key('emma-watsons-box', 'ima-ssh-key-ask-me-anything')

      expect(client).to have_received(:add_key).with('emma-watsons-box', 'ima-ssh-key-ask-me-anything')
    end
  end

end
