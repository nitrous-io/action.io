AIO.AccountSettingsIndexView = Em.View.extend
  templateName: 'templates/account_settings/index'
  classNames: ['app_page', 'index']
  elementId: 'account_settings_index_view'

  didClickChangePassword: ->
    @$('#change_password_link').addClass 'hide'
    @$('#password_fields').removeClass 'hide'

  didClickUpdate: ->
    @get('controller').updateProfile()

