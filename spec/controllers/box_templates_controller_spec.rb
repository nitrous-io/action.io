require 'spec_helper'

describe BoxTemplatesController do
  describe 'GET index' do
    let(:user)  { create :user }

    def do_request
      get :index, format: 'json'
    end

    context "when signed in as admin" do
      before do
        user.update_attribute(:admin, true)

        sign_in user
        do_request
      end

      it { should respond_with :success }
      its('response.body') { should == { box_templates: BoxTemplate.all.serialize_as_hash }.to_json }
    end

    context "when not signed in as admin" do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }
      its('response.body') { should == { box_templates: BoxTemplate.available_to_regular_users.load.serialize_as_hash }.to_json }
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET show' do
    let!(:box_template) { create :box_template }
    let(:user)          { create :user }

    def do_request(params={id: box_template.id})
      get :show, { format: 'json' }.merge(params)
    end

    context 'with valid id' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }
      its('response.body') { should == box_template.serialize_as_json }
    end

    context 'with invalid id' do
      it 'raises record not found' do
        expect {
          sign_in user
          do_request id: 'bs id'
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
