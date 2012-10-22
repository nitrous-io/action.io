AIO.IdeModalDialogView = Em.View.extend
  classNames: ['modal', 'hide', 'fade']

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

  viewDidAppear: ->

  didClickCancel: ->
    this.hide()

