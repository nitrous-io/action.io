require 'spec_helper'

shared_examples_for "an action that returns stats for a given model" do |klass, stats_method, endpoint, value|
  let!(:endpoint) { endpoint }

  def do_request(params={})
    get endpoint, { key: 'key', format: 'json' }.merge(params)
  end

  context 'when key is invalid' do
    it 'responds with 403' do
      do_request(key: 'invalid_key')
      expect(controller).to respond_with :forbidden
    end
  end

  context 'with key is valid' do
    before do
      klass.stub(stats_method).and_return(value)
    end

    it 'should return with boxes count' do
      expect(klass).to receive(stats_method).exactly(1).times.and_return(value)
      do_request
    end

    it 'should respond with success' do
      do_request
      expect(controller).to respond_with :success
    end
  end
end


describe StatsController do
  before :each do
    expect(Settings).to receive(:stats_api_key).and_return 'key'
  end

  describe 'GET boxes_count_by_group' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :count_by_group,
                                                                      :boxes_count_by_group,
                                                                      { 'count' => { 'us-west-1' => 100, 'eu-west-1' => 200 } }

    context 'when a state param is sent' do
      def do_request(params={})
        get :boxes_count_by_group, { key: 'key', format: 'json' }.merge(params)
      end

      it 'should count boxes by region in the given state' do
        expect(Box).to receive(:count_by_group).with('region_name', 'state' => 'running')
        do_request group_name: 'region_name', state: 'running'
      end

      it 'should respond with success' do
        do_request group_name: 'region_name', state: 'running'
        expect(controller).to respond_with :success
      end
    end
  end

  describe 'GET boxes_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :count_by,
                                                                      :boxes_count,
                                                                      { 'count' => 1000 }
  end

  describe 'GET users_total_count' do
    it_behaves_like "an action that returns stats for a given model", User,
                                                                      :total_count,
                                                                      :users_count,
                                                                      { 'count' => 10000 }
  end
end

