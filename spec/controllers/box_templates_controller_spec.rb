require 'spec_helper'

describe BoxTemplatesController do
  describe 'GET index' do
    def do_request
      get :index, format: 'json'
    end

    before { do_request }

    it { should respond_with :success }
    its('response.body') { should == BoxTemplate.all.serialize_as_json }
  end

  describe 'GET show' do
    let!(:box_template) { create :box_template }

    def do_request(params={})
      get :show, { format: 'json' }.merge(params)
    end

    context 'with valid id' do
      before { do_request id: box_template.to_param }

      it { should respond_with :success }
      its('response.body') { should == box_template.serialize_as_json }
    end

    context 'with invalid id' do
      it 'raises record not found' do
        expect {
          do_request id: 'bs id'
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
