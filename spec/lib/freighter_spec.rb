require 'spec_helper'

describe Freighter do
  let!(:box_template)  { create :box_template, runtime: 'ruby' }
  let!(:user)          { create :user }
  let!(:boxhost) { create :dedicated_boxhost, ip: '1.2.3.4' }
  let!(:box) do
    b = create :box, name: 'rails-box', box_template: box_template, host: 'host.nitrous.io', owner: user, cpu_multiplier: 1, memory: 768, virtual_memory: 768, storage: 1250, boxhost: boxhost
    b.generate_key_pair
    b
  end
  let!(:freighter) { Freighter.new(box) }

  describe 'provision_box' do
    before do
      @auto_generated_public_key = box.key_pairs.first.public_key
      box.stub(:premium?).and_return false
      @params = {
        name: 'rails-box',
        image: Freighter::DEFAULT_IMAGE,
        callback_url: Freighter::WEBHOOK_PATH,
        state: "box_id:#{box.id},op:provision",
        public_key: [@auto_generated_public_key],
      }
    end

    context 'successful provisioning' do
      context 'without user-generated public keys' do
        it 'should make a call to the Freighter API which will provision a box' do
          stub_request(:post, "http://1.2.3.4:#{Freighter::PORT}/containers").
            with(body: @params, headers: {'Content-Type' => 'application/x-www-form-urlencoded'}).
            to_return(body: '{"status":"accepted"}', headers: {})
          expect(freighter.provision_box).to be_truthy
        end
      end

      context 'with user-generated public keys' do
        it 'should make a call to the Freighter API which will provision a box' do
          user_public_key = create :public_key, user: user, name: 'public-key-1'
          params = @params.merge(public_key: [@auto_generated_public_key, user_public_key.key])
          stub_request(:post, "http://1.2.3.4:#{Freighter::PORT}/containers").
            with(body: params, headers: {'Content-Type' => 'application/x-www-form-urlencoded'}).
            to_return(body: '{"status":"accepted"}')
          expect(freighter.provision_box).to be_truthy
        end
      end
    end

    context 'when box is in the middle of provisioning' do
      before { box.update_attribute :state, 'provisioning' }

      it 'should not make a call to the freighter API' do
        # the test should pass without stubbing HTTP requests
        expect(freighter.provision_box).to be_falsey
      end
    end

    context 'when box is in the failed state' do
      before { box.update_attribute :state, 'failed' }

      it 'should make a call to the freighter API which will provision a box' do
        stub_request(:post, "http://1.2.3.4:#{Freighter::PORT}/containers").
          with(body: @params, headers: {'Content-Type' => 'application/x-www-form-urlencoded'}).
          to_return(body: '{"status":"OK"}')
        expect(freighter.provision_box).to be_truthy
      end
    end
  end

  describe '#state_param' do
    it 'includes box_id by default' do
      expect(freighter.send :state_param).to include("box_id:#{box.id}")
    end

    it 'includes the operation when given' do
      expect(freighter.send :state_param, op: 'restart' ).to include("box_id:#{box.id},op:restart")
    end
  end
end

