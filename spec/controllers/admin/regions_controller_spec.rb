require 'spec_helper'

describe Admin::RegionsController do
  let!(:admin) { create :admin }
  let(:user) { create :user }

  before do
    sign_in admin
    basic_auth 'admin', 'admin'
  end

  describe 'GET index' do
    let!(:region_1) { create :region }
    let!(:region_2) { create :region }
    let!(:region_3) { create :region }

    def do_request(params={})
      get :index, params
    end

    context 'when signed in' do
      before { do_request }
      it { should respond_with :success }
      it { should render_template 'index' }

      it 'assigns all regions to @regions' do
        expect(assigns(:regions)).to eq([region_1, region_2, region_3])
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT go_up' do
    let(:region) { create :region, state: 'down' }

    before do
      allow_any_instance_of(Region).to receive(:push_maintainence_state_message).and_return(nil)
    end

    def do_request(params={})
      put :go_up, { id: region.to_param }.merge(params)
    end

    context 'when signed in' do
      context 'with a valid region' do
        before { do_request }

        it 'changes the region state to up' do
          expect(region.reload.state).to eq('up')
        end

        it 'shows a flash message' do
          flash[:notice].should =~ /state to up/
        end

        it { should redirect_to admin_regions_url }
      end

      context 'with an invalid region' do
        it 'raises record not found' do
          expect {
            do_request id: 9999
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT start_to_go_down' do
    let(:region) { create :region, state: :up }

    before do
      allow_any_instance_of(Region).to receive(:push_maintainence_state_message).and_return(nil)
    end

    def do_request(params={})
      put :start_to_go_down, { id: region.to_param }.merge(params)
    end

    context 'when signed in' do
      context 'with a valid region' do
        before { do_request }

        it 'changes the region state to down' do
          expect(region.reload.state).to eq('going_down')
        end

        it 'shows a flash message' do
          flash[:notice].should =~ /state to going_down/
        end

        it { should redirect_to admin_regions_url }
      end

      context 'with an invalid region' do
        it 'raises record not found' do
          expect {
            do_request id: 9999
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT go_down' do
    let(:region) { create :region, state: :going_down }

    before do
      allow_any_instance_of(Region).to receive(:push_maintainence_state_message).and_return(nil)
    end

    def do_request(params={})
      put :go_down, { id: region.to_param }.merge(params)
    end

    context 'when signed in' do
      context 'with a valid region' do
        before { do_request }

        it 'changes the region state to down' do
          expect(region.reload.state).to eq('down')
        end

        it 'shows a flash message' do
          flash[:notice].should =~ /state to down/
        end

        it { should redirect_to admin_regions_url }
      end

      context 'with an invalid region' do
        it 'raises record not found' do
          expect {
            do_request id: 9999
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT disable_box_creation' do
    let(:region) { create :region, state: :up }

    before do
      allow_any_instance_of(Region).to receive(:push_maintainence_state_message).and_return(nil)
    end

    def do_request(params={})
      put :disable_box_creation, { id: region.to_param }.merge(params)
    end

    context 'when signed in' do
      context 'with a valid region' do
        before { do_request }

        it 'changes the region state to box_creation_disabled' do
          expect(region.reload.state).to eq('box_creation_disabled')
        end

        it 'shows a flash message' do
          flash[:notice].should =~ /state to box_creation_disabled/
        end

        it { should redirect_to admin_regions_url }
      end

      context 'with an invalid region' do
        it 'raises record not found' do
          expect {
            do_request id: 9999
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT enable_box_creation' do
    let(:region) { create :region, state: :box_creation_disabled }

    before do
      allow_any_instance_of(Region).to receive(:push_maintainence_state_message).and_return(nil)
    end

    def do_request(params={})
      put :enable_box_creation, { id: region.to_param }.merge(params)
    end

    context 'when signed in' do
      context 'with a valid region' do
        before { do_request }

        it 'changes the region state to box_creation_enabled' do
          expect(region.reload.state).to eq('up')
        end

        it 'shows a flash message' do
          flash[:notice].should =~ /state to up/
        end

        it { should redirect_to admin_regions_url }
      end

      context 'with an invalid region' do
        it 'raises record not found' do
          expect {
            do_request id: 9999
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

end
