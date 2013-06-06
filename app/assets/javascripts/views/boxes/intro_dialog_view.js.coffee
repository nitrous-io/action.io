AIO.IntroDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/intro/main'
  elementId: 'intro_dialog_view'
  contentBinding: 'controller.introDialog' # BoxesIndexController

  activeScreen: null
  screens: [1, 2, 3, 4, 5]

  didInsertElement: ->
    @set 'activeScreen', 1

  didClickDone: ->
    content = @get 'content'
    if user = content.user
      user.endIntro()

  setActiveScreen: (screen) ->
    @set 'activeScreen', screen

  activateNextScreen: ->
    @incrementProperty 'activeScreen'

AIO.IntroScreenView = Em.View.extend
  classNameBindings: ['hide']
  hide: true
  screenId: null

  showScreen: ( ->
    if parentView = @get 'parentView'
     activeScreen = parentView.get 'activeScreen'
     screenId = @get 'screenId'
     if (screenId == activeScreen)
       @set 'hide', false
      else
        @set 'hide', true
  ).observes 'parentView.activeScreen'

  didClickNext: ->
    if parentView = @get 'parentView'
      parentView.activateNextScreen()

AIO.IntroFullNameView = AIO.IntroScreenView.extend
  templateName: 'templates/intro/full_name'
  screenId: 1

AIO.IntroBasicDetailsView = AIO.IntroScreenView.extend
  templateName: 'templates/intro/basic_details'
  screenId: 2

AIO.IntroLanguagesView = AIO.IntroScreenView.extend
  templateName: 'templates/intro/languages'
  screenId: 3

AIO.IntroSocialConnectionsView = AIO.IntroScreenView.extend
  templateName: 'templates/intro/social_connections'
  screenId: 4

AIO.IntroInviteFriendsView = AIO.IntroScreenView.extend
  templateName: 'templates/intro/invite_friends'
  screenId: 5

AIO.IntroScreenSwitchButton = Em.View.extend
  tagName: 'button'
  classNames: ['btn']
  screen: null

  click: (event) ->
    if parentView = @get 'parentView'
      parentView.setActiveScreen @get('screen')
