require 'spec_helper'

describe FreighterController do
  let(:user) { create :user }
  let!(:box) { create :box, owner: user }

  before :each do
    allow_any_instance_of(Box).to receive(:push_box_updated_message).and_return nil
  end

  def do_request(payload)
    post :webhook, payload
  end

  context 'when created message is received' do
    let!(:freighter) { instance_double('Freighter') }

    before do
      allow_any_instance_of(Box).to receive(:api).and_return freighter
      freighter.stub(:start_box).and_return(true)
      box.update_attribute(:state, 'provisioning')
    end

    context 'successful creation' do
      it 'should start the box' do
        expect(freighter).to receive(:start_box).and_return(true)

        do_request(
          result: 'created',
          container: {
            id: '2cf1503ed6a0',
            name: 'foobar',
            image: 'freighter.foobar',
            host: '1.2.3.4',
            ssh_port: 10000,
            state: 'running'
          },
          state: "box_id:#{box.id},op:provision"
        )

        box.reload
        expect(box.port).to eq(10000)
        expect(box.state).to eq('starting')

        expect(response.status).to eq(200)
      end
    end

    context 'unsuccessful creation' do
      it 'should NOT make a call to start the box, but transition from provisioning to failed' do
        expect(freighter).not_to receive(:start_box)

        do_request(
          error: 'pc load letter',
          state: "box_id:#{box.id},op:provision"
        )

        expect(box.reload.state).to eq('failed')
        expect(response.status).to eq(409)
      end
    end
  end

  context 'when started message is received' do
    let!(:freighter) { instance_double('Freighter') }

    before do
      allow_any_instance_of(Box).to receive(:api).and_return freighter
      @success_params = {
        result: "started",
        container: {
          id: '2cf1503ed6a0',
          name: 'foobar',
          image: 'freighter.foobar',
          host: '1.2.3.4',
          ssh_port: 10000,
          state: 'running'
        },
        state: "box_id:#{box.id},op:start"
      }
    end

    context 'when box is starting' do
      before { box.update_attribute(:state, 'starting') }

      it 'changes the state of the box from starting to running on success' do
        do_request(@success_params)
        box.reload
        expect(box.state).to eq('running')
        expect(response.status).to eq(200)
      end

      it 'does not update box state on freighter error' do
        do_request(
          error: 'pc load letter',
          state: "box_id:#{box.id},op:start"
        )
        expect(box.reload.state).to eq('starting')
        expect(response.status).to eq(409)
      end
    end

    context 'when box is already running' do
      before do
        box.update_attribute(:state, 'running')
      end

      it 'should not try to start the box' do
        do_request(@success_params)
        expect(box).not_to receive(:transition_triggered)
        expect(response.status).to eq(200)
      end
    end

    context 'when box is neither starting nor running' do
      before do
        box.update_attribute(:state, 'stopped')
        do_request(@success_params)
      end

      it 'should not try to start the box' do
        expect(box).not_to receive(:transition_triggered)
      end

      it { should respond_with :conflict }
    end
  end

  context 'when stopped message is received' do
    before do
      @success_params = {
        result: 'stopped',
        container: {
          id: '2cf1503ed6a0',
          name: 'foobar',
          image: 'freighter.foobar',
          host: '',
          ssh_port: 10000,
          state: 'stopped'
        },
        state: "box_id:#{box.id},op:stop"
      }
    end

    context 'when box is stopping' do
      before { box.update_attribute(:state, 'stopping') }

      it 'changes the state of the box from stopping to stopped on success' do
        do_request(@success_params)

        expect(box.reload.state).to eq('stopped')
        expect(response.status).to eq(200)
      end

      it 'does not update box state on freighter error' do
        do_request(
          error: 'pc load letter',
          state: "box_id:#{box.id},op:stop"
        )
        expect(box.reload.state).to eq('stopping')
        expect(response.status).to eq(409)
      end
    end

    context 'when box is stopped' do
      before { box.update_attribute(:state, 'stopped') }

      it 'should not try to stop the box' do
        do_request(@success_params)

        expect(box.reload.state).to eq('stopped')
        expect(response.status).to eq(200)
      end
    end

    context 'when box is neither stopping nor stopped' do
      before do
        box.update_attribute(:state, 'running')
        do_request(@success_params)
      end

      it "should not change the box's state" do
        expect(box.reload.state).to eq('running')
      end

      it { should respond_with :conflict }
    end
  end

  context 'when restarted message is received' do
    before do
      @success_params = {
        result: 'restarted',
        container: {
          id: '2cf1503ed6a0',
          name: 'foobar',
          image: 'freighter.foobar',
          host: '1.2.3.4',
          ssh_port: 10000,
          state: 'running'
        },
        state: "box_id:#{box.id},op:restart"
      }
    end

    context 'when box is restarting' do
      before { box.update_attribute(:state, 'restarting') }

      it 'should change the state of the box from restarting to running' do
        do_request(@success_params)

        expect(box.reload.state).to eq('running')
        expect(response.status).to eq(200)
      end

      it 'does not update box state on freighter error' do
        do_request(
          error: 'pc load letter',
          state: "box_id:#{box.id},op:restart"
        )
        expect(box.reload.state).to eq('restarting')
        expect(response.status).to eq(409)
      end
    end

    context 'when box is already running' do
      before do
        box.update_attribute(:state, 'running')
      end

      it 'should not try to restart the box nor update its specs' do
        do_request(@success_params)

        expect(box).not_to receive(:transition_triggered)
        expect(box.reload.state).to eq('running')
        expect(response.status).to eq(200)
      end
    end

    context 'when box is neither restarting nor running' do
      before do
        box.update_attribute(:state, 'stopped')
        do_request(@success_params)
      end

      it "should not change the box's state" do
        expect(box.reload.state).to eq('stopped')
      end

      it { should respond_with :conflict }
    end
  end

  context 'when a terminated message is received' do
    before do
      @success_params = {
        result: 'terminated',
        container: {
          id: '2cf1503ed6a0',
        },
        state: "box_id:#{box.id},op:terminate"
      }
    end

    context 'when box is terminating' do
      before { box.update_attribute(:state, 'terminating') }

      it 'should change the state of the box from terminating to terminated' do
        do_request(@success_params)

        expect(box.reload.state).to eq('terminated')
        expect(response.status).to eq(200)
      end

      it 'does not update box state on freighter error' do
        do_request(
          error: 'pc load letter',
          state: "box_id:#{box.id},op:terminate"
        )
        expect(box.reload.state).to eq('terminating')
        expect(response.status).to eq(409)
      end

      context 'when box owner is deleted' do
        before { box.update_attribute :owner_id, nil }

        it 'should change the state of the box from terminating to terminated' do
          do_request(@success_params)

          expect(box.reload.state).to eq('terminated')
          expect(response.status).to eq(200)
        end
      end
    end

    context 'when box is already terminated' do
      before { box.update_attribute(:state, 'terminated') }

      it 'should not try to terminate the box' do
        do_request(@success_params)

        expect(box.reload.state).to eq('terminated')
        expect(response.status).to eq(200)
      end
    end

    context 'when box is neither terminating nor terminated' do
      before do
        box.update_attribute(:state, 'running')
        do_request(@success_params)
      end

      it "should not change the box's state" do
        expect(box.reload.state).to eq('running')
      end

      it { should respond_with :conflict }
    end
  end

  context 'is temporarily disabled in production' do
    before do
      Rails.env.stub(:production?).and_return(true)
      do_request({})
    end

    it { should respond_with :forbidden }
  end
end
