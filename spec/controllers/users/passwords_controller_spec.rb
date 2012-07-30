require 'spec_helper'

describe Users::PasswordsController do
  it 'is a subclass of Devise::PasswordsController' do
    Devise::PasswordsController.subclasses.should include Users::PasswordsController
  end
end
