require 'spec_helper'

describe Admin::AppUpdatesController do
  let!(:admin) { create :admin }

  before do
    sign_in admin
    basic_auth 'admin', 'admin'
  end

  describe 'GET index' do
    let!(:app_update_1) { create :app_update }
    let!(:app_update_2) { create :app_update }
    let!(:app_update_3) { create :app_update }

    def do_request(params={})
      get :index, params
    end

    context 'when signed in' do
      before { do_request }
      it { should respond_with :success }
      it { should render_template 'index' }

      it 'assigns all mac app update objects to @app_updates' do
        expect(assigns(:app_updates)).to eq([app_update_3, app_update_2, app_update_1])
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'GET new' do
    def do_request(params={})
      get :new, params
    end

    context 'when signed in' do
      before { do_request }
      it { should respond_with :success }
      it { should render_template 'new' }

      it 'assigns a new mac app object to @app_update' do
        expect(assigns(:app_update)).to be_new_record
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'POST create' do
    def do_request(params={})
      post :create, { app_update: { platform: 'windows', version: '1.0', title: 'version 1.0', release_notes: '* initial release', url: 'http://storage.com/app-1.0.dmg', file_size: 2.megabytes } }.merge(params)
    end

    context 'with valid params' do
      it 'creates an item' do
        expect {
          do_request
        }.to change { AppUpdate.count }.by(1)
        u = AppUpdate.last
        expect(u.platform).to eq('windows')
        expect(u.version).to eq('1.0')
        expect(u.title).to eq('version 1.0')
        expect(u.release_notes).to eq('* initial release')
        expect(u.url).to eq('http://storage.com/app-1.0.dmg')
        expect(u.file_size).to eq(2.megabytes)
        expect(assigns(:app_update)).to eq(u)
        expect(response).to redirect_to admin_app_update_url(u)
      end
    end

    context 'with invalid params' do
      it 'does not create an item' do
        expect {
          do_request app_update: { title: nil }
        }.to change { AppUpdate.count }.by(0)

        expect(controller).to respond_with :success
        expect(response).to render_template 'new'
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'GET show' do
    let!(:app_update) { create :app_update }

    def do_request(params={})
      get :show, { id: app_update.to_param }.merge(params)
    end

    context 'when an object with a given id exist' do
      before { do_request }

      it { should respond_with :success }
      it { should render_template :show }

      it 'assigns the mac app object to @app_update' do
        expect(assigns(:app_update)).to eq(app_update)
      end
    end

    context 'when an object with a given id does not exist' do
      it 'raises ActiveRecord::RecordNotFound error' do
        expect { do_request id: 9001 }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'GET edit' do
    let!(:app_update) { create :app_update }

    def do_request(params={})
      get :edit, { id: app_update.to_param }.merge(params)
    end

    context 'when an object with a given id exist' do
      before { do_request }

      it { should respond_with :success }
      it { should render_template :edit }

      it 'assigns the mac app object to @app_update' do
        expect(assigns(:app_update)).to eq(app_update)
      end
    end

    context 'when an object with a given id does not exist' do
      it 'raises ActiveRecord::RecordNotFound error' do
        expect { do_request id: 9001 }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT update' do
    let!(:app_update) { create :app_update }

    def do_request(params={})
      put :update, { id: app_update.to_param, app_update: { title: 'version over 9000' } }.merge(params)
    end

    context 'with valid params' do
      it 'updates the item' do
        expect {
          do_request
        }.to change { app_update.reload.title }.to('version over 9000')

        expect(assigns(:app_update)).to eq(app_update)
        expect(response).to redirect_to admin_app_update_url(app_update)
      end

      context 'when published is true' do
        before { app_update.update_attribute :published_at, nil }

        context 'when file_size is not 0' do
          it 'sets published_at to current time' do
            Timecop.freeze do
              do_request id: app_update.to_param, app_update: { published: true }
              expect(app_update.reload.published_at.to_i).to eq(Time.zone.now.to_i)
            end
          end
        end

        context 'when file_size is 0' do
          before { app_update.update_attribute :file_size, 0 }

          it 'fails validation' do
            Timecop.freeze do
              do_request id: app_update.to_param, app_update: { published: true }
              expect(app_update.reload.published_at.to_i).not_to eq(Time.zone.now.to_i)
            end
            expect(controller).to respond_with :success
            expect(response).to render_template 'edit'
          end
        end
      end

      context 'when published is false' do
        before { app_update.update_attribute :published_at, Time.zone.now }

        it 'sets published_at to nil' do
          expect {
            do_request id: app_update.to_param, app_update: { published: false }
          }.to change { app_update.reload.published_at }.to(nil)
        end
      end
    end

    context 'with invalid params' do
      it 'does not update the item' do
        expect {
          do_request id: app_update.to_param, app_update: { title: nil }
        }.not_to change { app_update.reload.title }.to('version over 9000')

        expect(controller).to respond_with :success
        expect(response).to render_template 'edit'
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'DELETE destroy' do
    let!(:app_update) { create :app_update }

    def do_request(params={})
      delete :destroy, { id: app_update.to_param }.merge(params)
    end

    context 'when an object with a given id exist' do
      it 'deletes the item' do
        expect {
          do_request
        }.to change { AppUpdate.count }.by(-1)

        expect(AppUpdate.find_by_id(app_update.id)).to be_nil
        expect(controller).to redirect_to admin_app_updates_url
      end
    end

    context 'when an object with a given id does not exist' do
      it 'raises ActiveRecord::RecordNotFound error' do
        expect { do_request id: 9001 }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end
end
