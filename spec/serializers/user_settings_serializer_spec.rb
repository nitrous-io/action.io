require 'spec_helper'

describe UserSettingsSerializer do
  let!(:user_settings) { create :user_settings }

  subject { user_settings.serialize_as_json }

  it 'has fields we expect it to have' do
    hash = JSON.parse(subject)['user_settings']
    expect(hash.delete('auto_close_brackets')).to eq(user_settings.auto_close_brackets)
    expect(hash.delete('highlight_line')).to eq(user_settings.highlight_line)
    expect(hash.delete('keybindings')).to eq(user_settings.keybindings)
    expect(hash.delete('match_brackets')).to eq(user_settings.match_brackets)
    expect(hash.delete('ruler_column')).to eq(user_settings.ruler_column)
    expect(hash.delete('show_line_numbers')).to eq(user_settings.show_line_numbers)
    expect(hash.delete('show_trailing_space')).to eq(user_settings.show_trailing_space)
    expect(hash.delete('soft_tabs')).to eq(user_settings.soft_tabs)
    expect(hash.delete('tab_size')).to eq(user_settings.tab_size)
    expect(hash.delete('theme')).to eq(user_settings.theme)
    expect(hash.delete('wrap_lines')).to eq(user_settings.wrap_lines)
    expect(hash).to be_empty
  end
end
