require 'spec_helper'

describe HomeController do
  describe 'GET index' do
    before { get :index }
    it { should render_template 'index' }
    it { should respond_with :success }
  end
end
