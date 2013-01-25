AIO.IdeImageView = Em.View.extend
  templateName: 'templates/ide/image'
  classNames: ['ide_image_view']

  document: null

  init: ->
    @_super()
    this.documentPathDidChange()

  didInsertElement: ->
    @_super()
    this.insertImage()

  willDestroyElement: ->
    @_super()

  insertImage: ->
    imageData = @get 'document.content'
    $imageContainer = @$('.image_container img')
    $imageContainer.attr 'src', "data:image/png;base64,#{imageData}"

  documentPathDidChange: (->
    if fileName = @get 'document.path.name'
      @set 'mode', AIO.FileTypeDetect.detect fileName
  ).observes 'document.path.name'

  didClickSave: ->
    @get('controller').saveDocument @get('document')

  didSelectMode: (event) ->
    selectedMode = event.context
    @set 'mode', selectedMode

  didSelectTabSize: (event) ->
    selectedTabSize = event.context
    @set 'tabSize', selectedTabSize

  didClickSoftTabToggle: ->
    @set 'softTabs', !@get('softTabs')

