AIO.Repository = AIO.Resource.extend
  box_id:         null
  name:           null
  full_name:      null
  clone_url:      null
  state:          null
  private:        null
  cloned_at:      null
  created_at:     null
  scm:            null
  language:       null
  failure_reason: null

  resourceUrl: '/repositories'
  resourceName: 'repository'
  resourceProperties: ['clone_url', 'box_id']

  box: (->
    AIO.get('router.boxesController').findById @get('box_id')
  ).property 'box_id'

  displayName: (->
    if @get('author') && @get('shortName')
      "#{@get 'author'}/#{@get 'shortName'}"
  ).property 'author', 'shortName'

  shortName: (->
    tokens = @get 'tokenizedCloneURL'
    tokens?.name
  ).property 'clone_url'

  author: (->
    tokens = @get 'tokenizedCloneURL'
    tokens?.author
  ).property 'clone_url'

  failed: (->
    @get('state') == 'failed'
  ).property 'state'

  supported: (->
    _.include(['git', 'mercurial'], @get('scm'))
  ).property 'scm'

  isGithub: (->
    @get('tokenizedCloneURL.author')? && @get('clone_url').match(/github\.com/)?
  ).property 'clone_url'

  tokenizedCloneURL: (->
    url = @get('clone_url')
    regex = ///
      ([^/]+)   # Last block before a "/"
      /
      ([^/]+?)  # Last block after a "/"
      (.git)?$  # Optionally ending with ".git"
    ///
    matches = url.match(regex)
    if matches
      {
        author: matches[1]
        name: matches[2]
      }
  ).property 'clone_url'

  identify: (callback) ->
    if @get('isGithub') == true
      author = @get('author')
      name   = @get('shortName')

      githubUser = new Gh3.User(author)
      githubRepo = new Gh3.Repository(name, githubUser)
      githubRepo.fetch (e) =>
        if e?
          @set 'state', 'failed'
        else
          @set 'scm', 'git'
          @set 'state', 'identified'
          @set 'language', githubRepo.language
        callback(e)
    else
      @set 'state', 'unsupported'
      callback null
