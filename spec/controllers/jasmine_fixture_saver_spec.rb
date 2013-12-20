require 'spec_helper'

describe HomeController do
  include JasmineFixtureSaver
  render_views

  specify '#index' do
    get :index
    expect(controller).to respond_with :success
    save_fixture(html_for('body'), 'home-index')
  end
end

