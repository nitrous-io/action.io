App.IdeTabView = Em.View.extend App.IdeTabViewMixin,
  templateName: 'templates/ide/tab'
  classNames: ['ide_tab_view']
  content: null

  closeTab: (->
    if @get 'content.path.deleted'
      this.remove()
  ).observes 'content.path.deleted'
