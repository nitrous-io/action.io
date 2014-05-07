require 'spec_helper'

describe ApplicationController do
  include JasmineFixtureSaver

  controller do
    def index
      render nothing: true
    end
  end

  render_views

  specify '#index' do
    get :index
    expect(controller).to respond_with :success
    save_fixture(html_for('body'), 'home-index')
  end
end
