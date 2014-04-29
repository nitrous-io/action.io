require 'spec_helper'

describe AutopartsController do
  describe 'POST webhook' do
    let!(:owner) { create :user }
    let!(:collaborator) { create :user }
    let!(:box) { create :box, owner: owner, users: [collaborator] }

    def do_request(params = {})
      post :webhook, {
        format: 'json',
        type: 'installed',
        part_name: 'some-part',
        part_version: '1.0',
        box_id: box.id.to_s,
        autoparts_version: 'Autoparts 0.0.1-abcd'
      }.merge(params)
    end

    context 'when a box is found for the given container name' do
      it 'sends parts_changed Shover message to all users of the box' do
        expect(Shover).to receive(:publish).with(owner.id, 'aio:parts_changed', { box_id: box.id })
        expect(Shover).to receive(:publish).with(collaborator.id, 'aio:parts_changed', { box_id: box.id })
        do_request
      end

      it 'tracks the event in Mixpanel' do
        expect(TrackMixpanelEventJob).to receive(:submit_job).with('Autopart Installed', owner.id, { part: 'some-part', part_version: '1.0', autoparts_version: 'Autoparts 0.0.1-abcd' })
        do_request
      end
    end

    context 'when a box is not found for the given id' do
      it 'does not send a parts_changed Shover message to all users of the box' do
        expect(Shover).to_not receive(:publish).with(owner.id, 'aio:parts_changed', instance_of(Hash))
        expect(Shover).to_not receive(:publish).with(collaborator.id, 'aio:parts_changed', instance_of(Hash))
        do_request box_id: '9999999'
      end

      it 'does not track the event in Mixpanel' do
        expect(TrackMixpanelEventJob).to_not receive(:submit_job)
        do_request box_id: '9999999'
      end
    end

    context 'when webhook request does not contain a type' do
      it 'sends parts_changed Shover message to all users of the box' do
        expect(Shover).to_not receive(:publish).with(owner.id, 'aio:parts_changed', instance_of(Hash))
        expect(Shover).to_not receive(:publish).with(collaborator.id, 'aio:parts_changed', instance_of(Hash))
        do_request type: nil
      end

      it 'does not track the event in Mixpanel' do
        expect(TrackMixpanelEventJob).to_not receive(:submit_job)
        do_request type: nil
      end
    end

    it 'should respond with ok in all contexts' do
      do_request
      expect(controller).to respond_with :ok
    end
  end
end
