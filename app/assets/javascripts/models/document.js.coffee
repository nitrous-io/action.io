EditSession = ace.require('ace/edit_session').EditSession

class AIO.Document extends AIO.Model
  initialize: ->
    @editSession = new EditSession('')
    @editSession.setUseWorker(false)

    this.on 'change:mode', (model, val) ->
      model.editSession.setMode(val)

    this.on 'change:tabSize', (model, val) ->
      model.editSession.setTabSize(val)

    this.on 'change:useSoftTabs', (model, val) ->
      model.editSession.setUseSoftTabs(val)

    this.set
      mode: 'ace/mode/aio_ruby'
      tabSize: 2
      useSoftTabs: true

  setContent: (content) ->
    @editSession.setValue(content)

  content: ->
    @editSession.getValue()

AIO.Document.setup('documents')

