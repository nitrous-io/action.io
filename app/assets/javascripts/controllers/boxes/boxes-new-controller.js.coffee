App.BoxesNewController = Em.ObjectController.extend
  boxNamePlaceholder: 'my-awesome-box'
  isIntro: false
  repo: null
  identifyTimedOut: false

  newRecord: ->
    @set 'content', App.Box.create()
    @set 'repo', App.Repository.create()
    @set 'repo.file_to_open', App.get('currentUser.intendedFileToOpen')

    @set 'boxNameIsDirty', false
    @handleIntent()

  save: ->
    record = @get 'content'
    repo = @get 'repo'

    doSave = =>
      record.save().then =>
        page = 'boxes.provisioning'
        page = 'intro.n2o' if @get 'isIntro'
        App.get('router').transitionTo page, id: record.get 'id'

    if repository_clone_url = @get('content.repository_clone_url')
      repo.set 'clone_url', repository_clone_url
      repo.identify (e) =>
        if e?
          @set 'content.saving', false
          @set 'content.errors',
            repository_clone_url: ['does not look like a valid Github repository']
        else
          record.set 'repository',
            clone_url: repo.get('clone_url')
            state: repo.get('state')
            scm: repo.get('scm')
            file_to_open: repo.get('file_to_open')
          doSave()
    else
      doSave()

  cancel: ->
    App.util.returnToSaved 'boxes.index'

  handleIntent: ->
    if cloneURL = App.get('currentUser').get('intendedCloneRepoURL')
      @set 'repository_clone_url', cloneURL

    if boxTemplate = App.get('currentUser').get('intendedBoxTemplate')
      @set 'box_template_id', boxTemplate.get('id')
    else
      @set 'box_template_id', App.get('boxTemplates.firstObject.id')
