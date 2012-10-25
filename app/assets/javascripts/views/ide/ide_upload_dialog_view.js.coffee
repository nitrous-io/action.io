AIO.IdeUploadDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/upload_dialog'
  elementId: 'ide_upload_dialog_view'
  contentBinding: 'controller.uploadDialog' # ideSidebarController
  classNameBindings: ['content.uploading:uploading']

  dragAndDropCapable: (->
    Modernizr.draganddrop
  ).property()

  uploadURI: (->
    if boxServerURI = AIO.get 'router.ideController.content.box_server_uri'
      "#{boxServerURI}/upload"
  ).property 'AIO.router.ideController.content.box_server_uri'

  didInsertElement: ->
    @_super()
    $files = @$ '.files'
    @$('.file_input').fileupload
      url: @get('uploadURI')
      xhrFields:
        withCredentials: true
      dataType: 'json'
      maxFileSize: 20 * 1000 * 1000
      singleFileUploads: true
      sequentialUploads: true
      dropZone: @$('.drop_zone')
      add: _.bind(@didAddUpload, this)
      progress: _.bind(@progressDidChange, this)
      done: _.bind(@uploadDidSucceed, this)
      fail: _.bind(@uploadDidFail, this)

  didAddUpload: (event, data) ->
    content = @get 'content'
    fileName = data.files[0].name
    if content && !content.get('uploading') && !content.findProperty('fileName', fileName)
      content.addObject AIO.Upload.create(data: data)

  progressDidChange: (event, data) ->
    if content = @get 'content'
      fileName = data.files[0].name
      upload = content.findProperty 'fileName', fileName
      upload.set 'progressInterval', data.progressInterval

  uploadDidSucceed: (event, data) ->
    if content = @get 'content'
      fileName = data.files[0].name
      upload = content.findProperty 'fileName', fileName
      upload.set 'completed', true
      token = data.result.tokens[0]
      path = content.get 'path.absolutePath'
      filePath = if path.length > 0
        "#{path}/#{fileName}"
      else
        fileName
      @get('controller').sendUploadToken filePath, token

  uploadDidFail: (event, data) ->
    if content = @get 'content'
      fileName = data.files[0].name
      upload = content.findProperty 'fileName', fileName
      upload.set 'completed', true
      upload.set 'failed', true
      @get('controller').didFinishAnUpload()

  didClickRemoveUpload: (event) ->
    if content = @get 'content'
      upload = event.context
      content.removeObject upload

  didClickUpload: ->
    @get('controller').beginUpload()

AIO.IdeUploadDialogDropZoneView = Em.View.extend
  classNames: ['drop_zone']
  classNameBindings: ['draggingOver:dragging_over']
  draggingOver: false

  dragOver: (event) ->
    @set 'draggingOver', true

  dragLeave: (event) ->
    @set 'draggingOver', false

  drop: (event) ->
    @set 'draggingOver', false

