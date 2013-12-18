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
      klass.should_receive(stats_method).exactly(1).times.and_return(value)
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
    Settings.should_receive(:stats_api_key).and_return 'key'
  end

  describe 'GET boxes_count_by_region' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :count_by_region,
                                                                      :boxes_count_by_region,
                                                                      { 'us-west-1' => 100, 'eu-west-1' => 200 }

    context 'when a state param is sent' do
      def do_request(params={})
        get :boxes_count_by_region, { key: 'key', format: 'json' }.merge(params)
      end

      it 'should count boxes by region in the given state' do
        Box.should_receive(:count_by_region).with(state: 'running')
        do_request state: 'running'
      end

      it 'should respond with success' do
        do_request state: 'running'
        expect(controller).to respond_with :success
      end
    end
  end

  describe 'GET boxes_count_by_template' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :count_by_template,
                                                                      :boxes_count_by_template,
                                                                      { 'ruby' => 100, 'java' => 200 }
  end

  describe 'GET boxes_count_by_memory' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :count_by_memory,
                                                                      :boxes_count_by_memory,
                                                                      { 2048 => 100, 384 => 200 }
  end

  describe 'GET boxes_count_by_storage' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :count_by_storage,
                                                                      :boxes_count_by_storage,
                                                                      { 2000 => 100, 750 => 200 }
  end

  describe 'GET boxes_running_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :running_count,
                                                                      :boxes_running_count,
                                                                      { 'count' => 1000 }
  end

  describe 'GET boxes_total_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :total_count,
                                                                      :boxes_total_count,
                                                                      { 'count' => 2000 }
  end

  describe 'GET boxes_unterminated_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :unterminated_count,
                                                                      :boxes_unterminated_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_born_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :born_count,
                                                                      :boxes_born_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_provisioning_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :provisioning_count,
                                                                      :boxes_provisioning_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_starting_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :starting_count,
                                                                      :boxes_starting_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_stopping_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :stopping_count,
                                                                      :boxes_stopping_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_stopped_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :stopped_count,
                                                                      :boxes_stopped_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_terminating_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :terminating_count,
                                                                      :boxes_terminating_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_terminated_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :terminated_count,
                                                                      :boxes_terminated_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_restarting_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :restarting_count,
                                                                      :boxes_restarting_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_reconfiguring_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :reconfiguring_count,
                                                                      :boxes_reconfiguring_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_failed_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :failed_count,
                                                                      :boxes_failed_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET boxes_migrating_count' do
    it_behaves_like "an action that returns stats for a given model", Box,
                                                                      :migrating_count,
                                                                      :boxes_migrating_count,
                                                                      { 'count' => 500 }
  end

  describe 'GET users_total_count' do
    it_behaves_like "an action that returns stats for a given model", User,
                                                                      :total_count,
                                                                      :users_total_count,
                                                                      { 'count' => 10000 }
  end
end

