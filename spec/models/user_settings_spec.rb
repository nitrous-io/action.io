require 'spec_helper'

describe UserSettings do
  it { should belong_to(:user) }

  it { should allow_mass_assignment_of :auto_close_brackets }
  it { should allow_mass_assignment_of :highlight_line }
  it { should allow_mass_assignment_of :keybindings }
  it { should allow_mass_assignment_of :match_brackets }
  it { should allow_mass_assignment_of :ruler_column }
  it { should allow_mass_assignment_of :show_line_numbers }
  it { should allow_mass_assignment_of :show_trailing_space }
  it { should allow_mass_assignment_of :soft_tabs }
  it { should allow_mass_assignment_of :tab_size }
  it { should allow_mass_assignment_of :theme }
  it { should allow_mass_assignment_of :wrap_lines }

  describe 'validations' do
    it { should ensure_inclusion_of(:keybindings).in_array(%w(default vim)) }
    it { should ensure_inclusion_of(:theme).in_array(UserSettings::AVAILABLE_THEMES) }
  end
end
