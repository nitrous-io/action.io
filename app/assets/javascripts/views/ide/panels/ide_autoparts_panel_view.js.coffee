AIO.IdeAutopartsPanelView = Em.View.extend
  elementId: 'ide_autoparts_panel_view'
  templateName: "templates/ide/panels/autoparts"

  loading: true
  hidden: true

  parts: null
  visibleParts: null

  filter: null
  loadParts: null
  searchTerm: null
  showInstalled: false

  didInsertElement: ->
    @_super()
    @set 'hidden', false

  willDestroyElement: ->
    @set 'hidden', true
    @set 'searchTerm', null

  # Try loading parts, only when dialog becomes visible and
  # if controller itself has finished loading the parts.
  _loadParts: (->
    return if @get 'hidden'
    console.log 'called load parts'
    @get('controller').all (parts) =>
      console.log 'got parts'
      @set 'parts', parts
      @set 'loading', false
  ).observes 'controller.parts', 'hidden'

  _searchForParts: (->
    @set 'loading', true
    @get('controller').search @get('searchTerm'), @get('showInstalled'), (matchingParts) =>
      @set 'parts', matchingParts
      @set 'loading', false
  ).observes 'searchTerm', 'showInstalled'
