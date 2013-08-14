require 'spec_helper'

describe AddonPlan do
  it { should belong_to(:addon) }
  it { should have_many(:addon_plan_benefits) }
end
