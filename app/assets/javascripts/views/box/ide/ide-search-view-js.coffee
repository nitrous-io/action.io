App.IdeSearchView = Em.View.extend
  templateName: 'templates/box/ide/search'
  classNames: ['ide_search_view']

  document: null

  didClickResult: (filename, line) ->
    # TODO filename will be relative to where the search is conducted, need to
    # handle paths that are not relative to home
    path = App.Path.create absolutePath: filename
    if sidebar = App.get('router.ideSidebarController')
      sidebar.openPath(path)
      Em.run.next ->
        # TODO handle case where file is not open and activeTab won't be
        # updated immediately
        if activeTab = App.get('router.ideEditorController.activeTab')
          activeTab.set('gotoLine', line.lineNumber)
