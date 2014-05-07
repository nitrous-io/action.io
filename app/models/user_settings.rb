class UserSettings < ActiveRecord::Base
  belongs_to :user

  EDITOR_SETTINGS = [
    :auto_close_brackets,
    :highlight_line,
    :keybindings,
    :match_brackets,
    :ruler_column,
    :show_line_numbers,
    :show_trailing_space,
    :soft_tabs,
    :tab_size,
    :theme,
    :wrap_lines,
  ]

  AVAILABLE_THEMES = [
    'base16-dark',
    'base16-light',
    'paraiso-light',
    'solarized dark',
    'solarized light',
    'tomorrow-night-eighties',
    'vibrant-ink',
  ]

  attr_accessible *EDITOR_SETTINGS

  validates_inclusion_of :keybindings, in: %w(default vim)
  validates_inclusion_of :theme, in: AVAILABLE_THEMES
end
