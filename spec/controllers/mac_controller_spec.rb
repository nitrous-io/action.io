require 'spec_helper'

describe MacController do
  describe 'GET index' do
    before do
      TrackMixpanelEventJob.stub(:submit_job)
    end

    context "user has not signed in " do
      before do
        TrackMixpanelEventJob.should_receive(:submit_job).with('Visited Mac App Homepage', nil)
        get :index
      end

      it { should respond_with :success }
      it { should render_template :index }
    end

    context "user has signed in" do
      let!(:user) { create :user }

      before do
        sign_in user
        TrackMixpanelEventJob.should_receive(:submit_job).with('Visited Mac App Homepage', user.id)
        get :index
      end

      it { should respond_with :success }
      it { should render_template :index }
    end
  end

  describe 'GET download' do
    let!(:mac_app_update1) { create :mac_app_update, published_at: 2.days.ago }
    let!(:mac_app_update2) { create :mac_app_update, published_at: nil }
    let!(:mac_app_update3) { create :mac_app_update, published_at: 3.day.ago }
    let!(:mac_app_update4) { create :mac_app_update, published_at: 1.day.ago }

    before { TrackMixpanelEventJob.stub(:submit_job) }

    context "user has not signed in" do
      before do
        TrackMixpanelEventJob.should_receive(:submit_job).with('Mac App Downloaded', nil)
        get :download
      end

      it { should redirect_to mac_app_update4.url }
    end

    context "user has signed in" do
      let!(:user) { create :user }

      before do
        sign_in user
        TrackMixpanelEventJob.should_receive(:submit_job).with('Mac App Downloaded', user.id)
        get :download
      end

      it { should redirect_to mac_app_update4.url }
    end

  end

  describe 'GET appcast' do
    let!(:mac_app_update1) { create :mac_app_update, published_at: 2.days.ago }
    let!(:mac_app_update2) { create :mac_app_update, published_at: nil }
    let!(:mac_app_update3) { create :mac_app_update, published_at: 3.day.ago }
    let!(:mac_app_update4) { create :mac_app_update, published_at: 1.day.ago }

    before { get :appcast }

    it 'assigns published MacAppUpdate items to @mac_app_updates' do
      expect(assigns(:mac_app_updates)).to eq([mac_app_update4, mac_app_update1, mac_app_update3])
    end

    it { should respond_with :success }
    it { should render_template 'mac/appcast' }
  end

  describe 'GET release_notes' do
    let!(:mac_app_update) { create :mac_app_update, version: '0.9.9-beta1', release_notes: "* bug fixes\n* more bug fixes" }

    def do_request(params={})
      get :release_notes, { version: mac_app_update.version }.merge(params)
    end

    context 'when an existing version is given' do
      before { do_request }

      it { should respond_with :success }

      it 'renders release_notes markdown markup as html' do
        html = Nokogiri.parse response.body
        expect(html.css 'ul li').to have(2).items
        expect(html.css('ul li')[0].text).to eq 'bug fixes'
        expect(html.css('ul li')[1].text).to eq 'more bug fixes'
      end
    end

    context 'when a non-existing version is given' do
      before { do_request version: '0.9.9-beta2' }

      it { should respond_with :not_found }
    end
  end
end
