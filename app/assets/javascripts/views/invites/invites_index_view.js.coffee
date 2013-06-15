AIO.InvitesIndexView = Em.View.extend
  templateName: 'templates/invites/index'
  classNames: ['app_page', 'invites', 'index']
  elementId: 'invites_index_view'
  availableInvitesBinding: Ember.Binding.oneWay("AIO.currentUser.available_invites")
  emailFieldText: null

  didClickInvite: ->
    if email = @get 'emailFieldText'
      @get('controller').sendInvite email
      @set 'emailFieldText', null

AIO.InvitesIndexTextField = Em.TextField.extend
  attributeBindings: ['placeholder']
  placeholder: 'hello@nitrous.io'

  insertNewline: ->
    @get('parentView')?.didClickInvite()
