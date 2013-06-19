AIO.ButtonCopyView = Em.View.extend
  tagName: 'a'
  classNames: ['button_copy_view', 'btn', 'btn-success']
  template: Em.Handlebars.compile("<i class=icon-cut></i>"),
  attributeBindings: ['title', 'data-clipboard-text'],
  title: 'copy to clipboard'
  value: null
  'data-clipboard-text': null

  didInsertElement: ->
    @_super()
    @clip = new ZeroClipboard(@$())

    @clip.on 'load', =>
      bridge = $(@clip.htmlBridge)
      bridge.tooltip title: => @get('title')

    @clip.on 'mouseout', =>
      @set 'title', 'copy to clipboard'

    @clip.on 'complete', =>
      @set 'title', 'copied!'
      bridge = $(@clip.htmlBridge)
      bridge.tooltip('show')
