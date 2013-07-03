require 'spec_helper'

describe TwitterHandler do
  let!(:user)          { create :user }

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

    context 'successfully follows nitrousio' do
      before do
        @twitter.client.should_receive(:follow).with('nitrousio').and_return []
      end

      it 'calls fill n2o for follow on current user' do
        user.should_receive(:fill_n2o_for_twitter_follow!)
        @twitter.follow
      end
    end

    context 'fails to follow nitrousio' do
      before do
        @twitter.client.should_receive(:follow).with('nitrousio').and_raise Twitter::Error::Unauthorized
      end

      it 'does not call fill n2o for follow on current user' do
        user.should_not_receive(:fill_n2o_for_twitter_follow!)
        @twitter.follow
      end

    end
  end
end
