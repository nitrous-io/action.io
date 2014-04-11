require 'spec_helper'

describe Coach do
  let!(:box_template)  { create :box_template, runtime: 'ruby' }
  let!(:user)          { create :user }
  let!(:region)        { create :region, coach_uri: 'https://coach.nitrous.io', enabled: true }
  let!(:box) do
    b = create :box, name: 'rails-box', region: region, box_template: box_template, host: 'host.nitrous.io', owner: user, cpu_multiplier: 1, memory: 768, virtual_memory: 768, storage: 1250
    b.generate_key_pair
    b
  end
  let!(:coach)         { Coach.new(box) }
  let(:container_name) { box.container_name }

  describe 'provision_box' do
    before do
      @auto_generated_public_key = box.key_pairs.first.public_key
      box.stub(:premium?).and_return false
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
                                 premium: 'false',
                                 public_keys: "[\"#{@auto_generated_public_key}\"]" } }).
            to_return(body: '{"status":"OK"}')
          expect(coach.provision_box).to be_truthy
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
                                 premium: 'false',
                                 public_keys: "[\"#{@auto_generated_public_key}\",\"#{public_key.key}\"]" } }).
            to_return(body: '{"status":"OK"}')
          expect(coach.provision_box).to be_truthy
        end
      end

      context 'with a source snapshot' do
        let!(:snapshot) { create :snapshot }

        before do
          box.box_template = nil
          box.source_snapshot = snapshot
          expect(box.source_snapshot).to eql snapshot
        end

        it 'sends the source snapshot ID and URL instead of a runtime to Coach' do
          stub_request(:post, "https://aio:foobar@coach.nitrous.io/boxes").
            with(query: { box: { name: 'rails-box',
                                 id: box.id,
                                 snapshot_id: snapshot.id,
                                 snapshot_url: snapshot.url,
                                 cpu_shares: '512',
                                 memory: '768M',
                                 virtual_memory: '768M',
                                 disk_space: '1250M',
                                 premium: 'false',
                                 public_keys: "[\"#{@auto_generated_public_key}\"]" } }).
            to_return(body: '{"status":"OK"}')
          expect(coach.provision_box).to be_truthy
        end
      end

      context 'with premium box' do
        before do
          box.stub(:premium?).and_return true
        end

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
          expect(coach.provision_box).to be_truthy
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
                                 premium: 'false',
                                 public_keys: "[\"#{@auto_generated_public_key}\"]" } }).
            to_return(body: '{"status":"MISSING"}')
        expect {
          expect(coach.provision_box).to be_truthy
        }.to raise_error Coach::CoachError
      end
    end

    context 'when box is in the middle of provisioning' do
      before { box.update_attribute :state, 'provisioning' }

      it 'should not make a call to the Coach API' do
        # the test should pass without stubbing HTTP requests
        expect(coach.provision_box).to be_falsey
      end
    end

    context 'when box is in the failed state' do
      before { box.update_attribute :state, 'failed' }

      it 'should make a call to the Coach API which will provision a box' do
        stub_request(:post, "https://aio:foobar@coach.nitrous.io/boxes").
          with(query: { box: { name: 'rails-box',
                               id: box.id,
                               runtime: 'ruby',
                               cpu_shares: '512',
                               memory: '768M',
                               virtual_memory: '768M',
                               disk_space: '1250M',
                               premium: 'false',
                               public_keys: "[\"#{@auto_generated_public_key}\"]" } }).
          to_return(body: '{"status":"OK"}')
        expect(coach.provision_box).to be_truthy
      end
    end
  end

  describe 'start_box' do
    before do
      @auto_generated_public_key = box.key_pairs.first.public_key
    end

    context 'box is not running' do
      before :each do
        stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/start").
          with(query: { box: {
                          boxer_id: 'host.nitrous.io',
                          public_keys: [@auto_generated_public_key],
                          data: {
                            memory: '768M',
                            diskSpace: '1000M',
                            virtualMemory: '768M',
                            cpuShares: 512
                          }.to_json } }).
          to_return(body: '{"status":"OK"}')
      end

      context 'box is stopped' do
        before { box.update_attribute :state, 'stopped' }

        it 'should make a call to the Coach API which will start a box' do
          expect(coach.start_box(memory: 768, disk_space: 1000, virtual_memory: 768, cpu_shares: 512)).to be_truthy
        end
      end

      context 'box is being provisioned' do
        before { box.update_attribute :state, 'provisioning' }

        it 'should make a call to the Coach API which will start a box' do
          expect(coach.start_box(memory: 768, disk_space: 1000, virtual_memory: 768, cpu_shares: 512)).to be_truthy
        end
      end

      context 'box is cloning a repo' do
        before { box.update_attribute :state, 'cloning_repo' }

        it 'should not make a call to the Coach API' do
          expect(coach.start_box(memory: 768, disk_space: 1000, virtual_memory: 768, cpu_shares: 512)).to be_falsey
        end
      end

      context 'box has user-uploaded public keys' do
        let!(:uploaded_public_key) { create :public_key, user: user }
        before { box.update_attribute :state, 'provisioning' }

        it "should make a call to the Coach API that includes the box's public keys" do
          stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/start").
            with(query: { box: {
                            boxer_id: 'host.nitrous.io',
                            public_keys: [@auto_generated_public_key, uploaded_public_key.key],
                            data: {
                              memory: '768M',
                              diskSpace: '1000M',
                              virtualMemory: '768M',
                              cpuShares: 512
                            }.to_json } }).
            to_return(body: '{"status":"OK"}')
          expect(coach.start_box(memory: 768, disk_space: 1000, virtual_memory: 768, cpu_shares: 512)).to be_truthy
        end
      end
    end

    context 'box is in the process of being started' do
      before { box.update_attribute :state, 'starting' }

      it 'should not make a call to the Coach API' do
        # the test should pass without stubbing HTTP requests
        expect(coach.start_box).to be_falsey
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
        expect(coach.stop_box).to be_truthy
      end
    end

    context 'when the box is stopping/stopped' do
      context 'when the box is stopping' do
        before { box.update_attribute :state, 'stopping' }

        it 'should not make a call to the coach API' do
          expect(coach.stop_box).to be_falsey
        end
      end

      context 'when the box is stopped' do
        before { box.update_attribute :state, 'stopped' }

        it 'should not make a call to the coach API' do
          expect(coach.stop_box).to be_falsey
        end
      end
    end
  end

  describe 'restart_box' do
    context 'when the box is running' do
      before { box.update_attribute :state, 'running' }

      before :each do
        stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/restart").
          with(query: { box: {
                        boxer_id: 'host.nitrous.io',
                        data: {
                          memory: '768M',
                          diskSpace: '1000M',
                          virtualMemory: '768M',
                          cpuShares: 512
                        }.to_json } }).
          to_return(body: '{"status":"OK"}')
      end

      it 'should make a call to the Coach API which will restart a box' do
        expect(coach.restart_box(memory: 768, disk_space: 1000, virtual_memory: 768, cpu_shares: 512)).to be_truthy
      end
    end

    context 'when the box is restarting' do
      before { box.update_attribute :state, 'restarting' }

      it 'should not make a call to the Coach API' do
        expect(coach.restart_box).to be_falsey
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
        expect(coach.terminate_box).to be_truthy
      end
    end

    context 'when the box is terminating' do
      before { box.update_attribute :state, 'terminating' }

      it 'should not make a call to the Coach API' do
        expect(coach.terminate_box).to be_falsey
      end
    end
  end

  describe 'snapshot_box' do
    let(:snapshot) { create :snapshot, id: 123 }

    context 'when the box is stopped' do
      before do
        stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/snapshot").
          with(query: { box: { boxer_id: 'host.nitrous.io', snapshot_id: '123' } }).
          to_return(body: '{"status":"OK"}')
      end

      it 'should make a call to the Coach API to snapshot the box' do
        expect(coach.snapshot_box(snapshot)).to be_truthy
      end
    end
  end

  describe 'delete_snapshot' do
    let(:snapshot) { create :snapshot, id: 123, state: 'completed', url: 's3://snapshots/snap-123.tar.gz' }

    before do
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/snapshots/123/destroy").
        with(query: { box: { boxer_id: 'host.nitrous.io' }, snapshot_url: 's3://snapshots/snap-123.tar.gz' }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API to delete the snapshot' do
      expect(coach.delete_snapshot(snapshot)).to be_truthy
    end
  end

  describe 'add_public_key' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io', data_type: 'aio:configure:add_public_key', data: 'public-key' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will add a public key to the box' do
      expect(coach.add_public_key('public-key')).to be_truthy
    end
  end

  describe 'remove_public_key' do
    before :each do
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io', data_type: 'aio:configure:remove_public_key', data: 'public-key' } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will remove a public key from the box' do
      expect(coach.remove_public_key('public-key')).to be_truthy
    end
  end

  describe '#reconfigure' do
    before do
      data = { memory: "512M", diskSpace: "1000M", virtualMemory: "1024M", cpuShares: 1024 }.to_json
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io', data_type: 'aio:configure:change_specs', data: data } }).
        to_return(body: '{"status":"OK"}')
    end

    it 'should make a call to the Coach API which will change the box specs' do
      expect(coach.reconfigure(memory: 512, disk_space: 1000, virtual_memory: 1024, cpu_shares: 1024)).to be_truthy
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
      expect(coach.migrate).to be_truthy
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

  describe '#update_custom_domain' do
    it 'makes a call to the Coach API which will change the box stored custom domain details' do
      box.custom_domain = 'wtf.com'
      data = JSON.dump custom_domain: 'wtf.com'
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}").
        with(query: { box: { boxer_id: 'host.nitrous.io', data_type: 'aio:configure:update_custom_domain', data: data }}).
        to_return(body: '{"status":"OK"}')
      coach.update_custom_domain
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

  describe '#download_repo_archive' do
    let(:repository) { instance_double('Repository') }

    before do
      allow(repository).to receive(:archive_url).and_return('https://github.com/nitrous-io/autoparts/archive/master.tar.gz')

      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/clone_repo").
        with(query: {
          box: {
            boxer_id: 'host.nitrous.io',
            repository_url: 'https://github.com/nitrous-io/autoparts/archive/master.tar.gz',
            repository_scm: 'targz'
          }
        }).
        to_return(body: '{"status":"OK"}')
    end

    it 'makes a call to the Coach API to download the repo as an archive' do
      expect(coach.download_repo_archive(repository)).to be_truthy
    end
  end

  describe '#clone_repo' do
    before do
      stub_request(:put, "https://aio:foobar@coach.nitrous.io/boxes/#{container_name}/clone_repo").
        with(query: {
          box: {
            boxer_id: 'host.nitrous.io',
            repository_url: 'https://github.com/rails/rails.git',
            repository_scm: 'git'
          }
        }).
        to_return(body: '{"status":"OK"}')
    end

    it 'makes a call to the Coach API to clone the repo' do
      repo = Repository.new(clone_url: 'https://github.com/rails/rails.git')
      repo.scm = 'git'
      repo.state = 'identified'
      expect(coach.clone_repo(repo)).to be_truthy
    end
  end
end
