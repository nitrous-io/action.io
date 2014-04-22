App.IdeTabView = Em.View.extend App.IdeTabViewMixin,
  templateName: 'templates/ide/tab'
  classNames: ['ide_tab_view']
  classNameBindings: ['content.active']
  tagName: 'li'
  content: null

  closeTab: (->
    if @get 'content.path.deleted'
      this.remove()
  ).observes 'content.path.deleted'
