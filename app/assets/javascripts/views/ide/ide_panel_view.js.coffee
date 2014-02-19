AIO.IdePanelView = Em.View.extend
  content: null
  classNames: ['ide_panel_view']
  templateName: "templates/ide/panels/container"

  isAutopartsPanel: ->
    @get('content.id') == 'autoparts'
