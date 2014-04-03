App.BoxesNewController = Em.ObjectController.extend
  boxNamePlaceholder: 'my-awesome-box'
  isIntro: false
  repo: new App.Repository
  identifyTimedOut: false

  showCloneUrl: false

  newRecord: ->
    @set 'content', box = App.Box.create()
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
            repository_clone_url: ['does not look like a Git or Mercurial repository']
        else
          record.set 'repository',
            clone_url: repo.get('clone_url')
            state: repo.get('state')
            scm: repo.get('scm')
          doSave()
    else
      doSave()

  cancel: ->
    App.get('router').transitionTo 'boxes.index'

  handleIntent: ->
    box = @get 'content'
    if cloneURL = App.get('currentUser').get('intendedCloneRepoURL')
      @set 'showCloneUrl', true # TODO remove this line (and the showCloneUrl declaration at top of file) once clone feature is live for everyone
      box.set 'repository_clone_url', cloneURL

    if boxTemplate = App.get('currentUser').get('intendedBoxTemplate')
      box.set 'box_template_id', boxTemplate.get('id')
    else
      box.set 'box_template_id', App.get('boxTemplates.firstObject.id')
