AIO.IntroCloneRepoView = Em.View.extend
  templateName: 'templates/intro/intro_clone_repo'
  elementId: 'intro_clone_repo_view'
  classNames: ['app_page', 'intro']

  didClickFetchRepos: ->
    controller = @get 'controller'
    controller.fetchRepos()

  didClickCloneRepo: (event) ->
    repo = event.context
    @get('controller').clone repo

  didClickNextScreen: ->
    AIO.get('router').transitionTo 'intro.n2o', id: @get 'controller.content.id'
