AIO.IdeCollabMessageView = Em.View.extend
  templateName: 'templates/ide/collab_message'
  tagName: 'li'
  classNameBindings: ['content.isChatMessage:chat-message:event-message']
  content: null

  didClickOnFileLink: ->
    if filePath = @get 'content.data'
      path = AIO.Path.create absolutePath: filePath
      ideSidebarController = AIO.get 'router.ideSidebarController'
      if path && ideSidebarController
        ideSidebarController.openPath path
