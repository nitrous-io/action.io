require 'spec_helper'

describe TwitterHandler do
  let!(:user) { create :user }

  describe 'initialize' do
    context 'when user has authenticated a twitter account' do
      before do
        create :authentication, user: user, provider: 'twitter', token: 'auth_token', secret: 'auth_secret'
      end

      it 'sets the user' do
        twitter_handler = TwitterHandler.new(user)
        expect(twitter_handler.user).to eq user
      end

      it 'instantiates a new twitter client with the auth token/secret of given user' do
        Twitter::Client.should_receive(:new).with(oauth_token: 'auth_token', oauth_token_secret: 'auth_secret')
        TwitterHandler.new user
      end
    end

    context 'when user has not authenticated a twitter account' do
      it 'instantiates a new twitter client with the auth token/secret of given user' do
        expect { TwitterHandler.new user }.to raise_error TwitterHandler::NotAuthenticatedError
      end
    end
  end

  describe '#follow' do
    before do
      create :authentication, user: user, provider: 'twitter', token: 'auth_token', secret: 'auth_secret'
      @twitter = TwitterHandler.new user
    end

    def do_action
      @twitter.follow
    end

    context 'successfully follows nitrousio' do
      before do
        @twitter.client.should_receive(:follow).with('nitrousio').and_return []
      end

      it 'calls fill n2o for follow on current user' do
        user.should_receive(:fill_n2o_for_twitter_follow!)
        do_action
      end
    end

    context 'fails to follow nitrousio' do
      before do
        @twitter.client.should_receive(:follow).with('nitrousio').and_raise Twitter::Error::Unauthorized
      end

      it 'does not call fill n2o for follow on current user' do
        user.should_not_receive(:fill_n2o_for_twitter_follow!)
        do_action
      end

    end
  end

  describe '#tweet' do
    before do
      create :authentication, user: user, provider: 'twitter', token: 'auth_token', secret: 'auth_secret'
      @twitter = TwitterHandler.new user
    end

    def do_action
      @twitter.tweet "I love Nitrous.IO"
    end

    context 'successfully sends a tweet' do
      before do
        @twitter.client.should_receive(:update).with('I love Nitrous.IO').and_return []
      end

      it 'calls fill n2o for tweet on current user' do
        user.should_receive(:fill_n2o_for_tweet!)
        do_action
      end
    end

    context 'fails to send a tweet' do
      before do
        @twitter.client.should_receive(:update).with('I love Nitrous.IO').and_raise Twitter::Error::Unauthorized
      end

      it 'does not call fill n2o for tweet on current user' do
        user.should_not_receive(:fill_n2o_for_tweet!)
        do_action
      end
    end
  end

  describe "#followers_count" do
    let!(:twitter_user) { double :twitter_user }

    before do
      create :authentication, user: user, provider: 'twitter', token: 'auth_token', secret: 'auth_secret'
      @twitter = TwitterHandler.new user
      @twitter.client.stub(:user) { twitter_user }
      twitter_user.stub(:followers_count) { 42 }
    end

    context 'successfully retrieves followers_count' do
      it "should successfully retrieve followers count" do
        expect(@twitter.followers_count).to eq 42
      end
    end
  end

  describe "#handle" do
    let!(:twitter_user) { double :twitter_user }

    before do
      create :authentication, user: user, provider: 'twitter', token: 'auth_token', secret: 'auth_secret'
      @twitter = TwitterHandler.new user
      @twitter.client.stub(:user) { twitter_user }
      twitter_user.stub(:screen_name) { "twitterati" }
    end

    context 'successfully retrieves followers_count' do
      it "should successfully retrieve followers count" do
        expect(@twitter.handle).to eq "twitterati"
      end
    end
  end
end
