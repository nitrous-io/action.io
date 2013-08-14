require 'spec_helper'

describe AddonFeature do
  it { should belong_to(:addon) }
end
