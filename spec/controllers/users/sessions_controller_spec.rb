require 'spec_helper'

describe Users::SessionsController do
  it 'is a subclass of Devise::SessionsController' do
    Devise::SessionsController.subclasses.should include Users::SessionsController
  end
end

