AIO.IdeModalDialogView = Em.View.extend
  classNames: ['modal', 'hide', 'fade']
  attributeBindings: ['data-backdrop', 'data-keyboard', 'data-show']

  init: ->
    @_super()
    @set 'data-backdrop', 'static'
    @set 'data-keyboard', 'false'
    @set 'data-show', 'false'

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

