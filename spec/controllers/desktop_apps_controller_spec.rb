require 'spec_helper'

describe DesktopAppsController do
  describe 'GET index' do
    before do
      allow(TrackMixpanelEventJob).to receive(:submit_job)
    end

    context "user has not signed in " do
      before do
        expect(TrackMixpanelEventJob).to receive(:submit_job).with('Visited Desktop App Homepage', nil)
        get :index
      end

      it { should respond_with :success }
      it { should render_template :index }
    end

    context "user has signed in" do
      let!(:user) { create :user }

      before do
        sign_in user
        expect(TrackMixpanelEventJob).to receive(:submit_job).with('Visited Desktop App Homepage', user.id)
        get :index
      end

      it { should respond_with :success }
      it { should render_template :index }
    end
  end

  describe 'GET download' do
    let!(:app_update1) { create :app_update, platform: 'mac', published_at: 2.days.ago }
    let!(:app_update2) { create :app_update, platform: 'mac', published_at: nil }
    let!(:app_update3) { create :app_update, platform: 'mac', published_at: 3.day.ago }
    let!(:app_update4) { create :app_update, platform: 'mac', published_at: 1.day.ago }
    let!(:app_update5) { create :app_update, platform: 'windows', published_at: 2.day.ago }
    let!(:app_update6) { create :app_update, platform: 'windows', published_at: 1.day.ago }

    before do
      allow(TrackMixpanelEventJob).to receive(:submit_job)
      allow(SetMixpanelPropertyJob).to receive(:submit_job)
    end

    context "user has not signed in" do
      context 'when the platform param is mac' do
        before do
          expect(TrackMixpanelEventJob).to receive(:submit_job).with('Mac App Downloaded', nil)
          expect(SetMixpanelPropertyJob).to_not receive(:submit_job)
          get :download, platform: 'mac'
        end

        it { should redirect_to app_update4.url }
      end

      context 'when the platform param is windows' do
        before do
          expect(TrackMixpanelEventJob).to receive(:submit_job).with('Windows App Downloaded', nil)
          expect(SetMixpanelPropertyJob).to_not receive(:submit_job)
          get :download, platform: 'windows'
        end

        it { should redirect_to app_update6.url }
      end
    end

    context "user has signed in" do
      let!(:user) { create :user }

      before do
        sign_in user
        Timecop.freeze
        @now = Time.now

        expect(TrackMixpanelEventJob).to receive(:submit_job).with('Mac App Downloaded', user.id)
        expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, 'downloaded_mac_app', @now)

        get :download, platform: 'mac'
      end

      after { Timecop.return }

      it { should redirect_to app_update4.url }
    end

  end

  describe 'GET appcast' do
    let!(:app_update1) { create :app_update, published_at: 2.days.ago }
    let!(:app_update2) { create :app_update, published_at: nil }
    let!(:app_update3) { create :app_update, published_at: 3.day.ago }
    let!(:app_update4) { create :app_update, published_at: 1.day.ago }
    let!(:app_update5) { create :app_update, platform: 'windows', published_at: 2.day.ago }
    let!(:app_update6) { create :app_update, platform: 'windows', published_at: 1.day.ago }
    let!(:app_update7) { create :app_update, platform: 'windows', published_at: nil }

    context 'when platforms param is mac' do
      before { get :appcast, platform: 'mac' }

      it 'assigns published AppUpdate items to @app_updates' do
        expect(assigns(:platform)).to eq 'Mac'
        expect(assigns(:app_updates)).to eq([app_update4, app_update1, app_update3])
      end

      it { should respond_with :success }
      it { should render_template 'appcast' }
    end

    context 'when platforms param is windows' do
      before { get :appcast, platform: 'windows' }

      it 'assigns published AppUpdate items to @app_updates' do
        expect(assigns(:app_updates)).to eq([app_update6, app_update5])
      end

      it { should respond_with :success }
      it { should render_template 'appcast' }
    end
  end

  describe 'GET release_notes' do
    let!(:app_update1) { create :app_update, version: '0.9.9-beta1', release_notes: "* bug fixes\n* more bug fixes", platform: 'mac' }
    let!(:app_update2) { create :app_update, version: '0.9.9-beta1', release_notes: "* bug fixes\n* more bug fixes", platform: 'windows' }
    let!(:app_update3) { create :app_update, version: '0.9.9-beta2', release_notes: "* bug fixes\n* more bug fixes", platform: 'windows' }
    let!(:app_update4) { create :app_update, version: '1.0.0',       release_notes: "* bug fixes\n* more bug fixes", platform: 'mac' }

    def do_request(params={})
      get :release_notes, { version: '0.9.9-beta1', platform: 'windows' }.merge(params)
    end

    context 'when a version that exists is given' do
      before { do_request }

      it { should respond_with :success }

      it 'renders release_notes markdown markup as html' do
        html = Nokogiri.parse response.body
        expect(html.css('ul li').size).to eq(2)
        expect(html.css('ul li')[0].text).to eq 'bug fixes'
        expect(html.css('ul li')[1].text).to eq 'more bug fixes'
      end
    end

    context 'when a non-existent version is given' do
      before { do_request version: '0.9.9-beta2', platform: 'mac' }

      it { should respond_with :not_found }
    end
  end
end
