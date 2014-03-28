AIO.IdeModalDialogView = Em.View.extend
  classNames: ['modal', 'hide', 'fade']
  attributeBindings: ['data-backdrop', 'data-keyboard', 'data-show', 'tabindex']

  init: ->
    @_super()
    @set 'data-backdrop', 'static'
    @set 'data-keyboard', 'true'
    @set 'data-show', 'false'
    @set 'tabindex', -1

  showOrHide: (->
    if @get 'content'
      this.show()
    else
      this.hide()
  ).observes 'content'

  show: ->
    @$().modal 'show'
    window.setTimeout =>
      this.viewDidAppear()
    , 500

  hide: ->
    @$().modal 'hide'
    @set 'content', null
    window.setTimeout =>
      this.viewDidDisappear()
    , 500

  viewDidAppear: ->

  viewDidDisappear: ->

  didClickCancel: ->
    this.hide()

