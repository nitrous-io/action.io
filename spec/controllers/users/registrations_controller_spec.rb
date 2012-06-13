require 'spec_helper'

describe Users::RegistrationsController do
  it 'is a subclass of Devise::RegistrationsController' do
    Devise::RegistrationsController.subclasses.should include Users::RegistrationsController
  end

end

