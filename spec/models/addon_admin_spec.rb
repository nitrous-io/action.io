require 'spec_helper'

describe AddonAdmin do
  it { should belong_to :addon }
  it { should belong_to :user  }

  it { should_not allow_mass_assignment_of :addon_id }
  it { should_not allow_mass_assignment_of :user_id  }
end
