require 'spec_helper'

describe BillingProfile do
  it { should belong_to(:user) }
end
