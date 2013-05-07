AIO.IdePathNameView = Em.View.extend
  templateName: 'templates/ide/path_name'
  tagName: 'a'
  classNameBindings: ['path.loading:loading', 'path.beingDeleted:deleted']

  path: null
