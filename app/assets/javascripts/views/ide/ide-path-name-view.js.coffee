App.IdePathNameView = Em.View.extend
  templateName: 'templates/ide/path-name'
  tagName: 'a'
  classNameBindings: ['path.loading:loading', 'path.beingDeleted:deleted']

  path: null
