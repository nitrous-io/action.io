require 'spec_helper'

describe Coach do
  let(:box_template) { create :box_template, runtime: 'ruby' }
  let(:user)         { create :user }
  let(:region)       { create :region, coach_uri: 'https://coach.action.io' }
  let(:box)          { create :box, name: 'rails-box', region: region, box_template: box_template, host: 'host.action.io', owner: user }
  let(:coach)        { Coach.new(box) }

  before { Box.any_instance.stub :push_box_added_message }

  describe 'provision_box' do
    before do
      # This is the public key created in the after_create callback in the Box
      @auto_generated_public_key = box.key_pairs.first.public_key
    end

    context 'successful provisioning' do
      context 'without user-generated public keys' do
        it 'should make a call to the Coach API which will provision a box' do
          stub_request(:post, "https://aio:foobar@coach.action.io/boxes").
            with(query: { box: { name: 'rails-box',
                                 id: box.id,
                                 runtime: 'ruby',
                                 memory: '256M',
                                 disk_space: '1G',
                                 public_keys: "[\"#{@auto_generated_public_key}\"]" } }).
            to_return(body: '{"status":"OK"}')
          coach.provision_box.should be_true
        end
      end

      context 'with user-generated public keys' do
        it 'should make a call to the Coach API which will provision a box' do
          public_key = create :public_key, user: user, name: 'public-key-1'
          stub_request(:post, "https://aio:foobar@coach.action.io/boxes").
            with(query: { box: { name: 'rails-box',
                                 id: box.id,
                                 runtime: 'ruby',
                                 memory: '256M',
                                 disk_space: '1G',
                                 public_keys: "[\"#{@auto_generated_public_key}\",\"#{public_key.key}\"]" } }).
            to_return(body: '{"status":"OK"}')
          coach.provision_box.should be_true
        end
      end
    end

    context 'unsuccessful provisioning' do
      it 'should make a call to the Coach API which will provision a box' do
        stub_request(:post, "https://aio:foobar@coach.action.io/boxes").
            with(query: { box: { name: 'rails-box',
                                 id: box.id,
                                 runtime: 'ruby',
                                 memory: '256M',
                                 disk_space: '1G',
                                 public_keys: "[\"#{@auto_generated_public_key}\"]" } }).
            to_return(body: '{"status":"MISSING"}')
        expect {
          coach.provision_box.should be_true
        }.to raise_error Coach::CoachError
      end
    end
  end

  describe 'start_box' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box/start").
        with(query: { box: { boxer_id: 'host.action.io' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will start a box' do
      coach.start_box.should be_true
    end
  end

  describe 'stop_box' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box/stop").
        with(query: { box: { boxer_id: 'host.action.io' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will start a box' do
      coach.stop_box.should be_true
    end
  end

  describe 'restart_box' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box/restart").
        with(query: { box: { boxer_id: 'host.action.io' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will restart a box' do
      coach.restart_box.should be_true
    end
  end

  describe 'terminate_box' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box/destroy").
        with(query: { box: { boxer_id: 'host.action.io' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will start a box' do
      coach.terminate_box.should be_true
    end
  end

  describe 'add_public_key' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box").
        with(query: { box: { boxer_id: 'host.action.io', data_type: 'aio:configure:add_public_key', data: 'public-key' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will add a public key to the box' do
      coach.add_public_key('public-key').should be_true
    end
  end

  describe 'remove_public_key' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box").
        with(query: { box: { boxer_id: 'host.action.io', data_type: 'aio:configure:remove_public_key', data: 'public-key' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will remove a public key from the box' do
      coach.remove_public_key('public-key').should be_true
    end
  end
end
