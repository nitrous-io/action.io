AIO.InvitesIndexView = Em.View.extend
  templateName: 'templates/invites/index'
  classNames: ['app_page', 'invites', 'index']
  elementId: 'invites_index_view'
  emailFieldText: null

  didClickInvite: ->
    if email = @get 'emailFieldText'
      @get('controller').sendInvite email
      @set 'emailFieldText', null

AIO.InvitesIndexTextField = Em.TextField.extend
  attributeBindings: ['placeholder']
  placeholder: 'hello@nitrous.io'
  classNames: [ 'mailcheck' ]

  insertNewline: ->
    @get('parentView')?.didClickInvite()

AIO.InvitesReferralLinkTextField = Em.TextField.extend
  click: ->
    @$().select()

AIO.TwitterShareButtonView = Em.View.extend
  tagName: 'a'
  classNames: ['twitter-share-button']
  attributeBindings: ['href', 'url:data-url', 'text:data-text']

  href: "https://twitter.com/share"
  text: "Spin up your own dev environment to code in the cloud now! Get 250MB of additional space by using this link:"

  didInsertElement: ->
    Shareable.initTwitterButton document, 'script', 'twitter-wjs'

AIO.FacebookShareButtonView = Em.View.extend
  tagName: 'div'
  classNames: ['fb-like']
  attributeBindings: ['url:data-href', 'send:data-send', 'buttonLayout:data-layout', 'width:data-width', 'showFaces:data-show-faces', 'action:data-action']

  send: 'false'
  buttonLayout: 'button_count'
  width: '450'
  showFaces: 'false'
  action: 'like'

  didInsertElement: ->
    Shareable.initFacebookButton document, 'script', 'facebook-jssdk'

AIO.GooglePlusShareButtonView = Em.View.extend
  tagName: 'div'
  classNames: ['g-plus']
  attributeBindings: ['action:data-action', 'annotation:data-annotation', 'url:data-href']

  action: "share"
  annotation: "bubble"

  didInsertElement: ->
    Shareable.initGooglePlusButton()
