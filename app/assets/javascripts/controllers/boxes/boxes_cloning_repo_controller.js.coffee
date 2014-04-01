AIO.BoxesCloningRepoController = Em.ObjectController.extend
  content: null
  repository: null

  redirectBasedOnRepoState: (->
    if AIO.get('router.currentPath') == 'root.boxes.cloning_repo' && content = @get 'content'
      repo = @get('repository')
      switch repo.get('state')
        when 'cloned'
          Em.run.next ->
            AIO.get('router').transitionTo 'boxes.ide_with_repo', id: content.get('id'), repo_id: repo.get('id')
        when 'identifying'
          Em.run.once(this, 'setIdentifyTimeout')
        when 'identified'
          if repo.supported()
            this.startClone()
          else
            this.returnToPicker("This does not look like a Git or Mercurial repository.")
        when 'failed'
          true # no-op, template will pick up the failed state and update accordingly
  ).observes 'repository.state'

  startClone: ->
    content = @get 'content'
    content.cloneRepo @get('repository'), (e) =>
      if e?.base?[0]
        this.returnToPicker(e.base[0])

  returnToPicker: (errorMessage) ->
    AIO.set('router.boxesCloneRepoPickerController.errors', errorMessage)
    AIO.get('router').transitionTo 'boxes.clone_repo_picker'

  cloneCommand: (->
    command = switch @get 'repository.scm'
      when 'git' then 'git'
      when 'mercurial' then 'hg'
      else ''
    basename = @get 'repository.shortName'
    return null if command == '' || basename?.length == 0
    "#{command} clone #{@get 'repository.clone_url'} ~/workspace/#{basename}"
  ).property 'repository.scm', 'repository.clone_url'

  setIdentifyTimeout: ->
    Em.run.later(this, ->
      return if @get('repository.state') != 'identifying'
      this.returnToPicker("Timed out trying to access.  Please ensure this url is available online.")
    , 30 * 1000) # 30 seconds
