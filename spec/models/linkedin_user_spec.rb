require 'spec_helper'

describe LinkedinUser do
  let!(:user) { create :user }

  describe '#initialize' do
    it 'sets the user' do
      LinkedinUser.new(user).user.should == user
    end

    it 'sets a default value of nil for user' do
      LinkedinUser.new.user.should == nil
    end
  end

  describe '#client' do
    context 'when the user has authenticated with LinkedIn' do
      let!(:authentication) { create :authentication, provider: 'linkedin', user: user }

      it "returns a new LinkedIn::Client with the user's authentication details" do
        client = double
        LinkedIn::Client.should_receive(:new).with(Settings.linkedin_id, Settings.linkedin_secret) { client }
        client.should_receive(:authorize_from_access).with(authentication.token, authentication.secret)

        LinkedinUser.new(user).client.should == client
      end
    end

    context 'when the user has not authenticated with LinkedIn' do
      it 'returns nil' do
        LinkedinUser.new(user).client.should be_nil
      end
    end
  end

  describe '#has_company?' do
    let(:user) { create :user }

    it "returns false if user is present but there's no client" do
      linkedin_user = LinkedinUser.new(user)
      linkedin_user.stub(:client) { nil }

      linkedin_user.has_company?.should be_false
    end

    context 'when user can be authenticated with LinkedIn' do
      let(:linkedin_user) { LinkedinUser.new(user) }
      let(:client) { double('LinkedIn::Client') }

      before do
        linkedin_user.stub(:client) { client }
      end

      context 'and has at least one current position in their profile' do
        before do
          # See LinkedIn API docs: http://developer.linkedin.com/documents/profile-fields#fullprofile.
          client.stub(:profile).with(fields: %w(three-current-positions)).and_return({
            'three_current_positions' => {
              'total' => 1,
              'all' => [{
                'company' => { 'name' => 'Nitrous.IO' },
                'is_current' => true,
                'title' => 'Janitor'
              }]
            }
          })
        end

        it 'returns true' do
          linkedin_user.has_company?.should == true
        end
      end

      context 'and does not have a current position in their profile' do
        before do
          client.stub(:profile).with(fields: %w(three-current-positions)) {
            { 'three_current_positions' => { 'total' => 0 } }
          }
        end

        it 'returns false' do
          linkedin_user.has_company?.should == false
        end
      end
    end
  end

  describe '#profile' do
    let(:user) { create :user }

    it 'returns nil if user is not present' do
      LinkedinUser.new.profile.should be_nil
    end

    it "returns nil if user is present but there's no client" do
      linkedin_user = LinkedinUser.new(user)
      linkedin_user.stub(:client) { nil }

      linkedin_user.profile.should be_nil
    end

    it 'delegates to the client' do
      linkedin_user = LinkedinUser.new(user)
      client = double('LinkedIn::Client').as_null_object
      linkedin_user.stub(:client) { client }

      linkedin_user.profile(fields: %w(positions))

      expect(client).to have_received(:profile).with(fields: %w(positions))
    end
  end

  describe '#positions' do
    let(:user) { create :user }

    it "returns nil if user is present but there's no client" do
      linkedin_user = LinkedinUser.new(user)
      linkedin_user.stub(:client) { nil }

      linkedin_user.positions.should be_nil
    end

    it "returns all the user's positions in his LinkedIn profile" do
      linkedin_user = LinkedinUser.new(user)
      client = double('LinkedIn::Client')
      linkedin_user.stub(:client) { client }

      # See LinkedIn API docs: http://developer.linkedin.com/documents/profile-fields#positions
      client.should_receive(:profile).with(fields: %w(positions)).and_return({
        'positions' => {
          'total' => 2,
          'all' => [
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
          ]
        }
      })

      linkedin_user.positions.should == [
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
      ]
    end
  end
end
