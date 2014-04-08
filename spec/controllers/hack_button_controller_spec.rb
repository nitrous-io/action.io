require 'spec_helper'

describe HackButtonController do
  let(:user) { create :user }

  before do
    allow(TrackMixpanelEventJob).to receive :submit_job
  end

  describe 'GET index' do
    let!(:box_template) { create :box_template, runtime: 'rails' }

    def do_request(params={})
      get :index, { repo: 'rails/rails', runtime: 'rails', file_to_open: 'README.nitrous.md' }.merge(params)
    end

    context 'when a required param is missing' do
      context 'when repo param is missing' do
        before { do_request(repo: nil) }
        it { should redirect_to root_url }
      end

      context 'when runtime param is missing' do
        before { do_request(runtime: nil) }
        it { should redirect_to root_url }
      end
    end

    context 'handling repo param' do
      context 'no namespace' do
        before { do_request(repo: 'rails') }
        it { should redirect_to root_url }
      end

      context 'invalid character' do
        before { do_request(repo: 'rail$/rails') }
        it { should redirect_to root_url }
      end

      context 'double slash action' do
        before { do_request(repo: 'rails/rails/rails') }
        it { should redirect_to root_url }
      end

      context 'when repo name contains dots and dashes' do
        before { do_request(repo: 'nitrous-io/autoparts.js') }
        it { should_not redirect_to root_url }
      end
    end

    context 'when a non-existent runtime is given' do
      before { do_request(runtime: 'fails') }
      it { should redirect_to root_url }
    end

    context 'when signed in' do
      before { sign_in user }

      it "sets the user's intent" do
        do_request
        expect(user.reload.intent[:kind]).to eql 'clone_repo'
        expect(user.reload.intent[:data][:repo]).to eql 'rails/rails'
        expect(user.reload.intent[:data][:runtime]).to eql 'rails'
        expect(user.reload.intent[:data][:file_to_open]).to eql 'README.nitrous.md'
      end

      context 'when user has visible boxes' do
        let!(:box) { create :box, owner: user }

        it 'redirects to the box picker page' do
          do_request
          expect(response).to redirect_to('/app#/boxes/clone_repo_picker')
        end
      end

      context 'when user has no visible boxes' do
        it 'redirects to the new box page' do
          do_request
          expect(response).to redirect_to('/app#/intro/create')
        end
      end

      context 'when source param is given' do
        it 'tracks the event in Mixpanel, stating the source' do
          TrackMixpanelEventJob.should receive(:submit_job).with('Visited Hack Button Page', user.id, {
            repo: 'rails/rails',
            runtime: 'rails',
            source: 'embed'
          })
          do_request(source: 'embed')
        end
      end

      context 'when source param is not given' do
        it 'tracks the event in Mixpanel' do
          TrackMixpanelEventJob.should receive(:submit_job).with('Visited Hack Button Page', user.id, {
            repo: 'rails/rails',
            runtime: 'rails'
          })
          do_request
        end
      end
    end

    context 'when not signed in' do
      def do_request(params={})
        get :index, { repo: 'rails/rails', runtime: 'rails', file_to_open: 'README.nitrous.md' }.merge(params)
      end

      describe do
        before { do_request }
        it { should respond_with :success }
        it { should render_template :index }

        it 'assigns the repo name to @repo' do
          expect(assigns(:repo)).to eql 'rails/rails'
        end

        it 'assigns the sign up path with the intent encoded as a querystring to @sign_up_path' do
          path = assigns(:sign_up_path)
          expect(path).to match %r[#{new_user_registration_path}]
          encoded_intent = {
            kind: 'clone_repo',
            data: { repo: 'rails/rails', runtime: 'rails', file_to_open: 'README.nitrous.md' }
          }.to_query
          query = {
            intent: encoded_intent
          }
          expect(path).to match %r[#{query.to_param}]
        end

        it 'assigns the sign in path to @sign_in_path with a redirect back to itself' do
          path = assigns(:sign_in_path)
          expect(path).to match %r[#{new_user_session_path}]
          query = {
            redirect_to: hack_button_url(repo: 'rails/rails', runtime: 'rails', file_to_open: 'README.nitrous.md')
          }
          expect(path).to match %r[#{query.to_param}]
        end
      end

      context 'when source param is given' do
        it 'tracks the event in Mixpanel, stating the source' do
          TrackMixpanelEventJob.should receive(:submit_job).with('Visited Hack Button Page', nil, {
            repo: 'rails/rails',
            runtime: 'rails',
            source: 'embed'
          })
          do_request(source: 'embed')
        end
      end

      context 'when source param is not given' do
        it 'tracks the event in Mixpanel' do
          TrackMixpanelEventJob.should receive(:submit_job).with('Visited Hack Button Page', nil, {
            repo: 'rails/rails',
            runtime: 'rails'
          })
          do_request
        end
      end
    end
  end

  describe 'GET embed' do
    let!(:box_template1) { create :box_template }
    let!(:box_template2) { create :box_template }

    before { get :embed }

    it { should render_template 'embed' }
    it { should respond_with :ok }

    it 'sets ivars for the view' do
      expect(assigns(:box_templates)).to match_array([box_template1, box_template2])
    end
  end
end
