require 'spec_helper'

describe PublicKey do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :key }
  it { should_not allow_mass_assignment_of :user_id }

  it { should belong_to :user }

  describe 'validations' do
    let!(:public_key) { create :public_key }

    it { should validate_presence_of :user_id }
    it { should validate_presence_of :key }
    it { should validate_uniqueness_of(:key).scoped_to(:user_id).with_message('already exists') }

    it 'validates whether a given key is a valid public key' do
      public_key.key = 'some random string'
      public_key.should_not be_valid
      public_key.key = 'ssh-rsa ABCDEFGHIJKLMNOPQRSTUVWXYZ test@nitrous.io'
      public_key.should_not be_valid
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQC6dOZ1El2Zi7kDtuWr0MOVZKFAJ2zQLlHt3sZ7KnNGAlzoD45lDrbTW/hIDt5vM2g3SztVRpyqB7ZAWSMCeM0yAnx1mycE4xM1Rul7e/9yfmSLmmngOFbDm86SImPimhzQ+mylnoImLgjZFdglcILbQRscFLAXCAtcCsKmisf2Uw== test@nitrous.io'
      public_key.should be_valid
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMKcRCibHSPU5OUb0a9cOp+Ou/Hc1dupHfcctUpN55SK3/wXX7SB06cp3jB6E8pIusrHawuhUZ1sINCnes6Ygl+HaqY8xrjQWlUdo7Q0KP97UX85QkMsjMp/x5QmE49P3ArKKy6sUDMIV/eBS6VWFzIkdRBBvFiwxaPi/op8MIK6EzjmcUq0FsTbD2qqGuoVXtPYWcfjMHQ2FL0MBtYz6gVbqAijDsm7o/XV6y4HvMLNYmVJpb9FuGUqyo3/mKSZASE+0blDPuZq6OLUq9BlYSJZLzaggYrNNG1EHeP45Q9sGUQzQj889N6SB23JfA65El0UxisMzeZeYRJzUNTbSh test@nitrous.io'
      public_key.should be_valid
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDwKwu0i0B8QgZPBdIMKIHAuv6kQw/FrDyS9CyrUUOE1qMTPhRjCHrmPpBLbXht08M4uBuyGEz5XxbfIB09NWTxDZFAlTvka3WKJq3eRwfhCaJ47loja0jb4SrMxx90cQ71ExQdrXYCHepYXnmVJn7gS0mssKF0x2Ley5GbyjhIzZ/QjM8LZxcpX0F3JiW+syJcRcVS4RNF9auUU0W0MgoMHiaA2/UwX5KJofPSOOiMOYOcKLutqnAjXs4jPKf+oggABuv2/FWh8ugcZMyqTmXZoaYOiCqQ2AWDVjCKYqYDNW2Msgj0M/LrWMdqVbwa1lTcW6+87Cqqa+by0GDqzi5t test@nitrous.io'
      public_key.should be_valid
      public_key.key = 'ssh-dss AAAAB3NzaC1kc3MAAACBAMFLeLA7UgoEwJzwg6x3RRqDIQIisNkIewCDERWKLLWlql/xvv9TVKRwBUozF5uEmHpDp5zcXkJfnaTV6lXYi6N5fzZEIaFXlEYKMJkSV2JgaiI4nFDLVHtzNdpv+uirA1YEqfKT9C4SPvm+s+F5VoLiNQhfBRB8Nb2A4A+jf9tvAAAAFQDPtuuXXlu2YBqrMfCIjWrtIDrG2wAAAIEAiAL25xTl4iA2QtWO0qkYBVB7fRBO+VRBnkB8xlMezSHDyDOg7BZPfz4F62+ux67gVr3/6AmKP7gxRO70OWq38zYHr5pQj02jBuxdilj1yzzgLMga4Lg3rqdirnA6NcHTt4d0pSe34VU1NcyA3rgEkpPe1I20GtYYkH4gPb1ok2EAAACAO2UdrHxkXIyjr9iDj6Xdkk2TRePruCtOZVjptMoFLKv3uYSJwobkvuyiGDngaNBQERJasZ1AM9iIDaakX5rxdTev53zrZIuSRIaoHEKee/ByDunGAYiXWSOBSSmzXSlHBVl+CaWCJMov7jwDSXDB21X4Gvq+1sAE501j9VrWll4= test@test.com'
      public_key.should be_valid
    end

    context 'before validation' do
      it 'strips the whitespaces surrounding the public key' do
        public_key.key = " \t\n  some public key   \t\n"
        public_key.valid?
        public_key.key.should == 'some public key'
      end
    end
  end

  context 'before save' do
    let(:public_key) { build :public_key, name: nil, key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQC6dOZ1El2Zi7kDtuWr0MOVZKFAJ2zQLlHt3sZ7KnNGAlzoD45lDrbTW/hIDt5vM2g3SztVRpyqB7ZAWSMCeM0yAnx1mycE4xM1Rul7e/9yfmSLmmngOFbDm86SImPimhzQ+mylnoImLgjZFdglcILbQRscFLAXCAtcCsKmisf2Uw== test@nitrous.io' }

    context 'when teh name is not set' do
      it 'uses the comment fragment of the public key as the name' do
        public_key.save
        public_key.name.should == 'test@nitrous.io'
      end
    end

    context 'when the name is set' do
      it 'does not touch it' do
        public_key.name = 'my awesome key'
        public_key.save
        public_key.name.should == 'my awesome key'
      end
    end
  end

  context 'after create' do
    let(:public_key) { build :public_key }

    it 'calls enqueue_add_public_key_to_box' do
      public_key.should_receive(:enqueue_add_public_key_to_box)
      public_key.save
    end
  end

  context 'after destroy' do
    let(:public_key) { create :public_key }

    it 'calls enqueue_remove_public_key_from_box' do
      public_key.should_receive(:enqueue_remove_public_key_from_box)
      public_key.destroy
    end
  end

  describe '.enqueue_import_github_keys' do
    let(:user) { create :user }

    it 'enqueues an import github keys job' do
      ImportGitHubKeysJob.should_receive(:new).with(user.id).and_return(:import_gh_keys_job)
      Delayed::Job.should_receive(:enqueue).with(:import_gh_keys_job)
      PublicKey.enqueue_import_github_keys(user)
    end
  end

  describe '.import_github_keys' do
    let(:user) { create :user }

    before do
      allow_any_instance_of(PublicKey).to receive(:public_key_is_valid)
      create :public_key, user: user, name: 'existing key', key: 'some public key 2'
      Shover.stub(:publish)
    end

    def do_action
      PublicKey.import_github_keys(user)
    end

    context 'when the user has an authentication with a github access token' do
      let!(:channel) { double 'channel', trigger: nil }

      before do
        user.stub(:token_for).with('github') { 'G17HubAcc355T0k3n' }

        HTTParty.should_receive(:get).with('https://api.github.com/user/keys', headers: { 'Authorization' => 'token G17HubAcc355T0k3n' }) do
          double 'response', code: 200, parsed_response: [
            { 'title' => 'ssh key 1', 'key' => 'some public key 1' },
            { 'title' => 'ssh key 2', 'key' => 'some public key 2' },
            { 'title' => 'ssh key 3', 'key' => 'some public key 3' }
          ]
        end

        Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
      end

      it "makes a request to github to fetch the keys and then adds them to the user's public keys, skipping existing keys" do
        expect { do_action }.to change { PublicKey.count }.by 2

        user.reload
        user.public_keys.should include PublicKey.find_by_name_and_key('ssh key 1', 'some public key 1')
        user.public_keys.should include PublicKey.find_by_name_and_key('ssh key 3', 'some public key 3')
        user.public_keys.should_not include PublicKey.find_by_name_and_key('ssh key 2', 'some public key 2')
        user.public_keys.should include PublicKey.find_by_name_and_key('existing key',  'some public key 2')
      end

      it 'pushes aio:public_keys_updated notification' do
        expect(Shover).to receive(:publish) do |u, e, d|
          expect(u).to eq user.id
          expect(e).to eq 'aio:public_keys_updated'
          expect(d).to eq user.public_keys.reload.serialize_as_hash
        end

        channel.should_receive(:trigger) do |message, data|
          message.should == 'aio:public_keys_updated'
          data.should == user.public_keys.reload.serialize_as_hash
        end
        do_action
      end
    end

    context 'when the user does not have an authentication with a github access token' do
      before { user.stub(:token_for).with('github') { nil } }

      it 'does nothing' do
        expect { do_action }.not_to change { PublicKey.count }
      end
    end
  end

  describe '#key_fragment' do
    let(:public_key) { build :public_key }

    it 'returns the base64 key fragment from the key string' do
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQC6dOZ1El2Zi7kDtuWr0MOVZKFAJ2zQLlHt3sZ7KnNGAlzoD45lDrbTW/hIDt5vM2g3SztVRpyqB7ZAWSMCeM0yAnx1mycE4xM1Rul7e/9yfmSLmmngOFbDm86SImPimhzQ+mylnoImLgjZFdglcILbQRscFLAXCAtcCsKmisf2Uw== test@nitrous.io'
      public_key.key_fragment.should == 'AAAAB3NzaC1yc2EAAAADAQABAAAAgQC6dOZ1El2Zi7kDtuWr0MOVZKFAJ2zQLlHt3sZ7KnNGAlzoD45lDrbTW/hIDt5vM2g3SztVRpyqB7ZAWSMCeM0yAnx1mycE4xM1Rul7e/9yfmSLmmngOFbDm86SImPimhzQ+mylnoImLgjZFdglcILbQRscFLAXCAtcCsKmisf2Uw=='
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMKcRCibHSPU5OUb0a9cOp+Ou/Hc1dupHfcctUpN55SK3/wXX7SB06cp3jB6E8pIusrHawuhUZ1sINCnes6Ygl+HaqY8xrjQWlUdo7Q0KP97UX85QkMsjMp/x5QmE49P3ArKKy6sUDMIV/eBS6VWFzIkdRBBvFiwxaPi/op8MIK6EzjmcUq0FsTbD2qqGuoVXtPYWcfjMHQ2FL0MBtYz6gVbqAijDsm7o/XV6y4HvMLNYmVJpb9FuGUqyo3/mKSZASE+0blDPuZq6OLUq9BlYSJZLzaggYrNNG1EHeP45Q9sGUQzQj889N6SB23JfA65El0UxisMzeZeYRJzUNTbSh test@nitrous.io'
      public_key.key_fragment.should == 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDMKcRCibHSPU5OUb0a9cOp+Ou/Hc1dupHfcctUpN55SK3/wXX7SB06cp3jB6E8pIusrHawuhUZ1sINCnes6Ygl+HaqY8xrjQWlUdo7Q0KP97UX85QkMsjMp/x5QmE49P3ArKKy6sUDMIV/eBS6VWFzIkdRBBvFiwxaPi/op8MIK6EzjmcUq0FsTbD2qqGuoVXtPYWcfjMHQ2FL0MBtYz6gVbqAijDsm7o/XV6y4HvMLNYmVJpb9FuGUqyo3/mKSZASE+0blDPuZq6OLUq9BlYSJZLzaggYrNNG1EHeP45Q9sGUQzQj889N6SB23JfA65El0UxisMzeZeYRJzUNTbSh'
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDwKwu0i0B8QgZPBdIMKIHAuv6kQw/FrDyS9CyrUUOE1qMTPhRjCHrmPpBLbXht08M4uBuyGEz5XxbfIB09NWTxDZFAlTvka3WKJq3eRwfhCaJ47loja0jb4SrMxx90cQ71ExQdrXYCHepYXnmVJn7gS0mssKF0x2Ley5GbyjhIzZ/QjM8LZxcpX0F3JiW+syJcRcVS4RNF9auUU0W0MgoMHiaA2/UwX5KJofPSOOiMOYOcKLutqnAjXs4jPKf+oggABuv2/FWh8ugcZMyqTmXZoaYOiCqQ2AWDVjCKYqYDNW2Msgj0M/LrWMdqVbwa1lTcW6+87Cqqa+by0GDqzi5t test@nitrous.io'
      public_key.key_fragment.should == 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDwKwu0i0B8QgZPBdIMKIHAuv6kQw/FrDyS9CyrUUOE1qMTPhRjCHrmPpBLbXht08M4uBuyGEz5XxbfIB09NWTxDZFAlTvka3WKJq3eRwfhCaJ47loja0jb4SrMxx90cQ71ExQdrXYCHepYXnmVJn7gS0mssKF0x2Ley5GbyjhIzZ/QjM8LZxcpX0F3JiW+syJcRcVS4RNF9auUU0W0MgoMHiaA2/UwX5KJofPSOOiMOYOcKLutqnAjXs4jPKf+oggABuv2/FWh8ugcZMyqTmXZoaYOiCqQ2AWDVjCKYqYDNW2Msgj0M/LrWMdqVbwa1lTcW6+87Cqqa+by0GDqzi5t'
      public_key.key = 'ssh-dss AAAAB3NzaC1kc3MAAACBAMFLeLA7UgoEwJzwg6x3RRqDIQIisNkIewCDERWKLLWlql/xvv9TVKRwBUozF5uEmHpDp5zcXkJfnaTV6lXYi6N5fzZEIaFXlEYKMJkSV2JgaiI4nFDLVHtzNdpv+uirA1YEqfKT9C4SPvm+s+F5VoLiNQhfBRB8Nb2A4A+jf9tvAAAAFQDPtuuXXlu2YBqrMfCIjWrtIDrG2wAAAIEAiAL25xTl4iA2QtWO0qkYBVB7fRBO+VRBnkB8xlMezSHDyDOg7BZPfz4F62+ux67gVr3/6AmKP7gxRO70OWq38zYHr5pQj02jBuxdilj1yzzgLMga4Lg3rqdirnA6NcHTt4d0pSe34VU1NcyA3rgEkpPe1I20GtYYkH4gPb1ok2EAAACAO2UdrHxkXIyjr9iDj6Xdkk2TRePruCtOZVjptMoFLKv3uYSJwobkvuyiGDngaNBQERJasZ1AM9iIDaakX5rxdTev53zrZIuSRIaoHEKee/ByDunGAYiXWSOBSSmzXSlHBVl+CaWCJMov7jwDSXDB21X4Gvq+1sAE501j9VrWll4= test@test.com'
      public_key.key_fragment.should == 'AAAAB3NzaC1kc3MAAACBAMFLeLA7UgoEwJzwg6x3RRqDIQIisNkIewCDERWKLLWlql/xvv9TVKRwBUozF5uEmHpDp5zcXkJfnaTV6lXYi6N5fzZEIaFXlEYKMJkSV2JgaiI4nFDLVHtzNdpv+uirA1YEqfKT9C4SPvm+s+F5VoLiNQhfBRB8Nb2A4A+jf9tvAAAAFQDPtuuXXlu2YBqrMfCIjWrtIDrG2wAAAIEAiAL25xTl4iA2QtWO0qkYBVB7fRBO+VRBnkB8xlMezSHDyDOg7BZPfz4F62+ux67gVr3/6AmKP7gxRO70OWq38zYHr5pQj02jBuxdilj1yzzgLMga4Lg3rqdirnA6NcHTt4d0pSe34VU1NcyA3rgEkpPe1I20GtYYkH4gPb1ok2EAAACAO2UdrHxkXIyjr9iDj6Xdkk2TRePruCtOZVjptMoFLKv3uYSJwobkvuyiGDngaNBQERJasZ1AM9iIDaakX5rxdTev53zrZIuSRIaoHEKee/ByDunGAYiXWSOBSSmzXSlHBVl+CaWCJMov7jwDSXDB21X4Gvq+1sAE501j9VrWll4='
    end
  end

  describe '#comment_fragment' do
    let(:public_key) { build :public_key }

    it 'returns the comment fragment from the key string' do
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQC6dOZ1El2Zi7kDtuWr0MOVZKFAJ2zQLlHt3sZ7KnNGAlzoD45lDrbTW/hIDt5vM2g3SztVRpyqB7ZAWSMCeM0yAnx1mycE4xM1Rul7e/9yfmSLmmngOFbDm86SImPimhzQ+mylnoImLgjZFdglcILbQRscFLAXCAtcCsKmisf2Uw== test@nitrous.io'
      public_key.comment_fragment.should == 'test@nitrous.io'
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMKcRCibHSPU5OUb0a9cOp+Ou/Hc1dupHfcctUpN55SK3/wXX7SB06cp3jB6E8pIusrHawuhUZ1sINCnes6Ygl+HaqY8xrjQWlUdo7Q0KP97UX85QkMsjMp/x5QmE49P3ArKKy6sUDMIV/eBS6VWFzIkdRBBvFiwxaPi/op8MIK6EzjmcUq0FsTbD2qqGuoVXtPYWcfjMHQ2FL0MBtYz6gVbqAijDsm7o/XV6y4HvMLNYmVJpb9FuGUqyo3/mKSZASE+0blDPuZq6OLUq9BlYSJZLzaggYrNNG1EHeP45Q9sGUQzQj889N6SB23JfA65El0UxisMzeZeYRJzUNTbSh pete@nitrous.io'
      public_key.comment_fragment.should == 'pete@nitrous.io'
      public_key.key = 'ssh-dss AAAAB3NzaC1kc3MAAACBAMFLeLA7UgoEwJzwg6x3RRqDIQIisNkIewCDERWKLLWlql/xvv9TVKRwBUozF5uEmHpDp5zcXkJfnaTV6lXYi6N5fzZEIaFXlEYKMJkSV2JgaiI4nFDLVHtzNdpv+uirA1YEqfKT9C4SPvm+s+F5VoLiNQhfBRB8Nb2A4A+jf9tvAAAAFQDPtuuXXlu2YBqrMfCIjWrtIDrG2wAAAIEAiAL25xTl4iA2QtWO0qkYBVB7fRBO+VRBnkB8xlMezSHDyDOg7BZPfz4F62+ux67gVr3/6AmKP7gxRO70OWq38zYHr5pQj02jBuxdilj1yzzgLMga4Lg3rqdirnA6NcHTt4d0pSe34VU1NcyA3rgEkpPe1I20GtYYkH4gPb1ok2EAAACAO2UdrHxkXIyjr9iDj6Xdkk2TRePruCtOZVjptMoFLKv3uYSJwobkvuyiGDngaNBQERJasZ1AM9iIDaakX5rxdTev53zrZIuSRIaoHEKee/ByDunGAYiXWSOBSSmzXSlHBVl+CaWCJMov7jwDSXDB21X4Gvq+1sAE501j9VrWll4= test@test.com.sg'
      public_key.comment_fragment.should == 'test@test.com.sg'
    end
  end

  describe '#md5_fingerprint' do
    let(:public_key) { build :public_key }

    it 'returns the md5 fingerprint of the key' do
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCwBqUAjRpM0qOvvBDWKcXXJwrCTwh+uXxfzNm46MU9MLXG4XM6MIDnQJsLi5DLlrQWq1pLShQYrV0ctmW+H4QbxqsrqSMJU0bdwaFCnGb8keZn3zd3IagnIjkPb+d5MBBBH5Un9cdWbLwl25gHy+j5dHb+wvtljswsOZDihp10ow== test@test.com'
      public_key.md5_fingerprint.should == 'bc:68:22:0a:6b:31:18:f7:52:33:fe:af:d9:ed:9f:81'
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+62FfuCfHFhfDdc9nbjeqCPNr2GqVnRA7cekXXl/2J0lYbsvrmFyi2ivb7RQEFvWse+BGY9GOaQIUVdMLYbST4wnp7fwhCRTSk8rh73cNaO42Ielmvc10YaQsGIkzd6/+phNUDViXLB3SYmPjrfy1DPQH2NQivpmQ8oG5TdOxWRoygNU3xy32lcseVJEYFe/1/f+g8jSowWX+Q4yLP+qzQQFlBtbDxEVnBD/RCau0P3E86O6/juONQ3TG0sUVofKMXqb3S2JvcpODSYcq1OjXS8enExDqQC3YakS4l0ypL2dwzbfSrOVkWlzJWEpuU7tPqOh+5zTBWn+rYcCsskXF test@test.com'
      public_key.md5_fingerprint.should == '8f:68:69:5c:6f:8d:3e:e4:02:62:1b:48:ff:07:8f:cb'
    end
  end

  describe 'public key <-> box jobs' do
    let(:user) { create :user }
    let(:another_user) { create :user }
    let!(:box1) { create :box, owner: user, state: 'running' }
    let!(:box2) { create :box, owner: another_user }
    let!(:box3) { create :box, owner: another_user, users: [another_user, user], state: 'running' }
    let!(:box4) { create :box, owner: user, state: 'terminated' }
    let!(:box5) { create :box, owner: user, state: 'provisioning' }

    let!(:mock_coach) { double(:coach) }

    let!(:public_key) { create :public_key, user: user }

    describe '#enqueue_add_public_key_to_box' do
      it 'enqueues add public key to box jobs for each of the boxes owned by the user' do
        AddPublicKeyToBoxJob.should_receive(:submit_job).with(box1.id, public_key.key).and_return(:add_public_key_to_box_job_1)
        AddPublicKeyToBoxJob.should_receive(:submit_job).with(box3.id, public_key.key).and_return(:add_public_key_to_box_job_3)
        AddPublicKeyToBoxJob.should_not_receive(:submit_job).with(box2.id, public_key.key)
        AddPublicKeyToBoxJob.should_not_receive(:submit_job).with(box4.id, public_key.key)
        AddPublicKeyToBoxJob.should_not_receive(:submit_job).with(box5.id, public_key.key)
        public_key.enqueue_add_public_key_to_box
      end
    end

    describe '#enqueue_remove_public_key_from_box' do
      it 'enqueues remove public key form box jobs for each of the boxes owned by the user' do
        RemovePublicKeyFromBoxJob.should_receive(:submit_job).with(box1.id, public_key.key).and_return(:remove_public_key_to_box_job_1)
        RemovePublicKeyFromBoxJob.should_receive(:submit_job).with(box3.id, public_key.key).and_return(:remove_public_key_to_box_job_3)
        RemovePublicKeyFromBoxJob.should_not_receive(:submit_job).with(box2.id, public_key.key)
        RemovePublicKeyFromBoxJob.should_not_receive(:submit_job).with(box4.id, public_key.key)
        RemovePublicKeyFromBoxJob.should_not_receive(:submit_job).with(box5.id, public_key.key)

        public_key.enqueue_remove_public_key_from_box
      end
    end
  end
end
