class UserSettingsSerializer < ActiveModel::Serializer
  attributes *UserSettings::EDITOR_SETTINGS
end
