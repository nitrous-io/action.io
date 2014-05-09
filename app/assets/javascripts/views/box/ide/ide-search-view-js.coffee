App.IdeSearchView = Em.View.extend
  templateName: 'templates/box/ide/search'
  classNames: ['ide_search_view']

  document: null

  didClickResult: (filename, line) ->
    # TODO filename will be relative to where the search is conducted, need to
    # handle paths that are not relative to home
    path = App.Path.create absolutePath: filename
    if sidebar = App.get('router.ideSidebarController')
      sidebar.openPath path,
        done: (document) ->
          Em.run.next ->
            document.set('gotoLine', line.lineNumber)
