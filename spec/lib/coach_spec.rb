require 'spec_helper'

describe Coach do
  let!(:box_template) { create :box_template, image: 'ruby' }
  let!(:user)         { create :user }
  let!(:region)       { create :region, coach_uri: 'https://coach.action.io' }
  let!(:box)          { create :box, name: 'rails-box', region: region, box_template: box_template, host: 'host.action.io', owner: user }
  let!(:coach)        { Coach.new(box) }

  describe 'provision_box' do
    context 'successful provisioning' do
      context 'without public keys' do
        before :each do
          stub_request(:post, "https://aio:foobar@coach.action.io/boxes").
            with(query: { box: { name: 'rails-box', id: box.id, runtime: 'ruby', memory: 256, disk_space: 2048 } }).
            to_return(body: '{"status":"OK"}')
        end

        it 'should make a call to the Coach API which will provision a box' do
          coach.provision_box.should be_true
        end
      end

      context 'with public keys' do
        let!(:key_pair) { create :key_pair, private_key: 'private_key', public_key: 'public_key_1', box: box }
        let!(:public_key) { create :public_key, user: user, name: 'public-key-1' }

        before :each do
          stub_request(:post, "https://aio:foobar@coach.action.io/boxes").
            with(query: { box: { name: 'rails-box', id: box.id, runtime: 'ruby', memory: 256, disk_space: 2048, public_keys: "[\"public_key_1\",\"#{public_key.key}\"]" } }).
            to_return(body: '{"status":"OK"}')
        end

        it 'should make a call to the Coach API which will provision a box' do
          coach.provision_box.should be_true
        end
      end
    end

    context 'unsuccessful provisioning' do
      before :each do
        stub_request(:post, "https://aio:foobar@coach.action.io/boxes").
            with(query: { box: { name: 'rails-box', id: box.id, runtime: 'ruby', memory: 256, disk_space: 2048 } }).
            to_return(body: '{"status":"MISSING"}')
      end

      it 'should make a call to the Coach API which will provision a box' do
        expect {
          coach.provision_box.should be_true
        }.to raise_error Coach::CoachError
      end
    end
  end

  context 'start_box' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box/start").
        with(query: { box: { boxer_id: 'host.action.io' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will start a box' do
      coach.start_box.should be_true
    end
  end

  context 'stop_box' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box/stop").
        with(query: { box: { boxer_id: 'host.action.io' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will start a box' do
      coach.stop_box.should be_true
    end
  end

  context 'terminate_box' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box/destroy").
        with(query: { box: { boxer_id: 'host.action.io' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will start a box' do
      coach.terminate_box.should be_true
    end
  end

  context 'add_public_key' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.action.io/boxes/rails-box").
        with(query: { box: { boxer_id: 'host.action.io', data_type: 'aio:configure:add_public_key', data: 'public-key' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will add a public key to the box' do
      coach.add_public_key('public-key').should be_true
    end
  end

  context 'remove_public_key' do
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


