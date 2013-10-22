AIO.IdeTabView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/tab'
  classNames: ['ide_tab_view']
  content: null

  closeTab: (->
    if @get 'content.path.deleted'
      this.remove()
  ).observes 'content.path.deleted'
