require 'spec_helper'

describe Users::PasswordsController do
  it 'is a subclass of Devise::PasswordsController' do
    expect(Devise::PasswordsController.subclasses).to include Users::PasswordsController
  end
end
