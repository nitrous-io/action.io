require 'spec_helper'

describe Admin::BoxesController do
  let!(:user)  { create :user }
  let!(:admin) { create :admin }
  let!(:box)   { create :box, owner: user }

  before do
    sign_in admin
    basic_auth 'admin', 'admin'
  end

  describe 'GET index' do
    def do_request(params = {})
      get :index, params
    end

    context 'when signed in as admin' do
      context 'when page is requested without any user identifier' do
        before { do_request }
        it { should respond_with :success }
        it { should render_template 'index' }
      end

      context "when a valid box id given'" do
        it 'assigns the box' do
          do_request id: box.id
          expect(assigns(:box)).to eq(box)
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT retry_start' do
    let!(:box)   { create :box, owner: user }

    def do_request(params={})
      put :retry_start, { id: box.to_param }.merge(params)
    end

    context 'when signed in' do
      context 'with a box in starting state' do
        before do
          box.update_attribute 'state', 'starting'

          expect_any_instance_of(Box).to receive(:push_box_updated_message)
          expect_any_instance_of(Coach).to receive('start_box')

          do_request
        end

        it 'shows a flash message' do
          expect(flash[:notice]).to match(/Retrying start/)
        end
      end

      context 'with a box not in starting state' do
        before do
          box.update_attribute 'state', 'started'

          expect_any_instance_of(Coach).to_not receive('start_box')

          do_request
        end

        it 'does not show a flash message' do
          expect(flash[:notice]).to be_blank
        end
      end

      it 'should redirect back to boxes index page with the box set' do
        do_request
        expect(response).to redirect_to admin_boxes_url(id: box.to_param)
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT retry_restart' do
    let!(:box) { create :box, owner: user }

    def do_request(params={})
      put :retry_restart, { id: box.to_param }.merge(params)
    end

    context 'when signed in' do
      context 'with a box in restarting state' do
        before do
          box.update_attribute 'state', 'restarting'

          expect_any_instance_of(Box).to receive(:push_box_updated_message)
          expect_any_instance_of(Coach).to receive('restart_box')

          do_request
        end

        it 'shows a flash message' do
          expect(flash[:notice]).to match(/Retrying restart/)
        end
      end

      context 'with a box not in restarting state' do
        before do
          box.update_attribute 'state', 'running'

          expect_any_instance_of(Coach).to_not receive('restart_box')

          do_request
        end

        it 'does not show a flash message' do
          expect(flash[:notice]).to be_blank
        end
      end

      it 'should redirect back to boxes index page with the box set' do
        do_request
        expect(response).to redirect_to admin_boxes_url(id: box.to_param)
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT retry_stop' do
    let!(:box)   { create :box, owner: user }

    def do_request(params={})
      put :retry_stop, { id: box.to_param }.merge(params)
    end

    context 'when signed in' do
      context 'with a box in stopping state' do
        before do
          box.update_attribute 'state', 'stopping'

          expect_any_instance_of(Box).to receive(:push_box_updated_message)
          expect_any_instance_of(Coach).to receive('stop_box')

          do_request
        end

        it 'shows a flash message' do
          expect(flash[:notice]).to match(/Retrying stop/)
        end
      end

      context 'with a box not in stopping state' do
        before do
          box.update_attribute 'state', 'stopped'

          expect_any_instance_of(Coach).to_not receive('stop_box')

          do_request
        end

        it 'does not show a flash message' do
          expect(flash[:notice]).to be_blank
        end
      end

      it 'should redirect back to boxes index page with the box set' do
        do_request
        expect(response).to redirect_to admin_boxes_url(id: box.to_param)
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT force_terminate' do
    let!(:box)   { create :box, owner: user }

    def do_request(params={})
      put :force_terminate, { id: box.to_param }.merge(params)
    end

    context 'when signed in' do
      context 'with a box in terminating state' do
        before do
          box.update_attribute 'state', 'terminating'

          expect_any_instance_of(Box).to receive(:push_box_updated_message)

          do_request
        end

        it 'changes box state to terminated' do
          expect(box.reload.state).to eq('terminated')
        end

        it 'shows a flash message' do
          expect(flash[:notice]).to match(/Terminated box/)
        end
      end

      context 'with a box not in terminating state' do
        before do
          box.update_attribute 'state', 'terminated'

          do_request
        end

        it 'shows a flash message' do
          expect(flash[:notice]).to match(/already terminated/)
        end
      end

      it 'should redirect back to boxes index page with the box' do
        do_request
        expect(response).to redirect_to admin_boxes_url(id: box.to_param)
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end
end
