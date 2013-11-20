require 'spec_helper'

describe Coach do
  let!(:box_template)  { create :box_template, runtime: 'ruby' }
  let!(:user)          { create :user }
  let!(:region)        { create :region, coach_uri: 'https://coach.nitrous.io', enabled: true }
  let!(:box)           { create :box, name: 'rails-box', region: region, box_template: box_template, host: 'host.nitrous.io', owner: user, cpu_multiplier: 1, memory: 768, virtual_memory: 768, storage: 1250 }
  let!(:coach)         { Coach.new(box) }
  let(:container_name) { box.container_name }

  describe 'provision_box' do
    before do
      # This is the public key created in the after_create callback in the Box
      @auto_generated_public_key = box.key_pairs.first.public_key
      box.stub(:premium?).and_return true
    end

    context 'successful provisioning' do
      context 'without user-generated public keys' do
        it 'should make a call to the Coach API which will provision a box' do
          stub_request(:post, "https://aio:foobar@coach.nitrous.io/boxes").
            with(query: { box: { name: 'rails-box',
                                 id: box.id,
                                 runtime: 'ruby',
                                 cpu_shares: '512',
                                 memory: '768M',
                                 virtual_memory: '768M',
                                 disk_space: '1250M',
                                 premium: 'true',
                                 public_keys: "[\"#{@auto_generated_public_key}\"]" } }).
            to_return(body: '{"status":"OK"}')
          coach.provision_box.should be_true
        end
      end

      context 'with user-generated public keys' do
        it 'should make a call to the Coach API which will provision a box' do
          public_key = create :public_key, user: user, name: 'public-key-1'
          stub_request(:post, "https://aio:foobar@coach.nitrous.io/boxes").
            with(query: { box: { name: 'rails-box',
                                 id: box.id,
                                 runtime: 'ruby',
                                 cpu_shares: '512',
                                 memory: '768M',
                                 virtual_memory: '768M',
                                 disk_space: '1250M',
                                 premium: 'true',
                                 public_keys: "[\"#{@auto_generated_public_key}\",\"#{public_key.key}\"]" } }).
            to_return(body: '{"status":"OK"}')
          coach.provision_box.should be_true
        end
      end
    end

    context 'unsuccessful provisioning' do
      it 'should make a call to the Coach API which will provision a box' do
        stub_request(:post, "https://aio:foobar@coach.nitrous.io/boxes").
            with(query: { box: { name: 'rails-box',
                                 id: box.id,
                                 runtime: 'ruby',
                                 cpu_shares: '512',
                                 memory: '768M',
                                 virtual_memory: '768M',
                                 disk_space: '1250M',
                                 premium: 'true',
                                 public_keys: "[\"#{@auto_generated_public_key}\"]" } }).
            to_return(body: '{"status":"MISSING"}')
        expect {
          coach.provision_box.should be_true
        }.to raise_error Coach::CoachError
      end
    end

    context 'when box is in the middle of provisioning' do
      before { box.update_attribute :state, 'provisioning' }

      it 'should not make a call to the Coach API' do
        # the test should pass without stubbing HTTP requests
        coach.provision_box.should be_false
      end
    end

    context 'when box is in the failed state' do
      before { box.update_attribute :state, 'failed' }

      it 'should make a call to the Coach API which will provision a box' do
        stub_request(:post, "https://aio:foobar@coach.nitrous.io/boxes").
          with(query: { box: { name: 'rails-box',
                               id: box.id,
                               runtime: 'ruby',
                               cpu_shares: 512,
                               memory: '768M',
                               virtual_memory: '768M',
                               disk_space: '1250M',
                               premium: 'true',
                               public_keys: "[\"#{@auto_generated_public_key}\"]" } }).
          to_return(body: '{"status":"OK"}')
        coach.provision_box.should be_true
      end
    end
  end

  describe 'start_box' do
    context 'box is not running' do
      before :each do
        stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/start").
          with(query: { box: { boxer_id: 'host.nitrous.io' } }).
          to_return(body: '{"status":"OK"}')
      end

      context 'box is stopped' do
        before { box.update_attribute :state, 'stopped' }

        it 'should make a call to the Coach API which will start a box' do
          coach.start_box.should be_true
        end
      end

      context 'box is being provisioned' do
        before { box.update_attribute :state, 'provisioning' }

        it 'should make a call to the Coach API which will start a box' do
          coach.start_box.should be_true
        end
      end
    end

    context 'box is in the process of being started' do
      before { box.update_attribute :state, 'starting' }

      it 'should not make a call to the Coach API' do
        # the test should pass without stubbing HTTP requests
        coach.start_box.should be_false
      end
    end
  end

  describe 'stop_box' do
    context 'when the box is running' do
      before { box.update_attribute :state, 'running' }

      before :each do
        stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/stop").
          with(query: { box: { boxer_id: 'host.nitrous.io' } }).
          to_return(body: '{"status":"OK"}')
      end

      it 'should make a call to the Coach API which will start a box' do
        coach.stop_box.should be_true
      end
    end

    context 'when the box is stopping/stopped' do
      context 'when the box is stopping' do
        before { box.update_attribute :state, 'stopping' }

        it 'should not make a call to the coach API' do
          coach.stop_box.should be_false
        end
      end

      context 'when the box is stopped' do
        before { box.update_attribute :state, 'stopped' }

        it 'should not make a call to the coach API' do
          coach.stop_box.should be_false
        end
      end
    end
  end

  describe 'restart_box' do
    context 'when the box is running' do
      before { box.update_attribute :state, 'running' }

      before :each do
        stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/restart").
          with(query: { box: { boxer_id: 'host.nitrous.io' } }).
          to_return(body: '{"status":"OK"}')
      end

      it 'should make a call to the Coach API which will restart a box' do
        coach.restart_box.should be_true
      end
    end

    context 'when the box is restarting' do
      before { box.update_attribute :state, 'restarting' }

      it 'should not make a call to the Coach API' do
        coach.restart_box.should be_false
      end
    end
  end

  describe 'terminate_box' do
    context 'when the box is stopped' do
      before do
        box.update_attribute :state, 'stopped'
        stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/destroy").
          with(query: { box: { boxer_id: 'host.nitrous.io' } }).
          to_return(body: '{"status":"OK"}')
      end

      it 'should make a call to the Coach API which will terminate the box' do
        coach.terminate_box.should be_true
      end
    end

    context 'when the box is terminating' do
      before { box.update_attribute :state, 'terminating' }

      it 'should not make a call to the Coach API' do
        coach.terminate_box.should be_false
      end
    end
  end

  describe 'add_public_key' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io', data_type: 'aio:configure:add_public_key', data: 'public-key' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will add a public key to the box' do
      coach.add_public_key('public-key').should be_true
    end
  end

  describe 'remove_public_key' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io', data_type: 'aio:configure:remove_public_key', data: 'public-key' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will remove a public key from the box' do
      coach.remove_public_key('public-key').should be_true
    end
  end

  describe '#reconfigure' do
    before do
      data = { memory: "512M", diskSpace: "1000M", virtualMemory: "1024M" }.to_json
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io', data_type: 'aio:configure:change_specs', data: data } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will change the box specs' do
      coach.reconfigure(memory: 512, disk_space: 1000, virtual_memory: 1024).should be_true
    end
  end

  describe '#fetch_box_info' do
    before do
      stub_request(:get, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will change the box specs' do
      expect(coach.fetch_box_info).to be true
    end
  end

  describe '#migrate' do
    it 'should make a call to the Coach API which will provision a box' do
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{box.container_name}/migrate").
        with(query: { box: {
          id: box.id,
          boxer_id: box.host } }).
        to_return(body: '{"status":"OK"}')
      coach.migrate.should be_true
    end
  end

  describe '#update_auth' do
    it 'makes a call to the Coach API which will change the box stored authentication details' do
      box.auth_username = 'admin'
      box.auth_password = 'password'
      data = JSON.dump auth_username: 'admin', auth_password: 'password'
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io', data_type: 'aio:configure:update_auth', data: data }}).
        to_return(body: '{"status":"OK"}')
      coach.update_auth
    end
  end

  describe '#update_premium' do
    it 'makes a call to the Coach API which will change the box premium flag' do
      box.stub(:premium?).and_return true
      data = JSON.dump premium: true
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io', data_type: 'aio:configure:update_premium', data: data }}).
        to_return(body: '{"status":"OK"}')
      coach.update_premium
    end
  end
end
