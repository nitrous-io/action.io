AIO.IntroCloneRepoController = Em.ObjectController.extend
  content: null
  repositories: null
  loadingRepos: false
  loadingReposInfo: null

  initialize: ->
    this.fetchRepos()

  clone: (repo) ->
    # TODO Make an AJAX request to kick of a DJ to clone the repo to the box.
    box = @get 'content'
    console.log '!! Cloning', repo, 'to', box

  fetchRepos: (->
    return if @get 'loadingRepos'
    return if @get 'repositories'

    if AIO.get('currentUser.isGithubAuthenticated')
      @set 'loadingRepos', true
      @set 'loadingReposInfo', null
      $.ajax(
        type: 'GET',
        dataType: 'json',
        url: '/user/fetch_git_hub_repositories'
      ).fail (e) =>
        @set 'loadingRepos', false
        @set 'loadingReposInfo', 'Failed to load repositories from GitHub.'
  ).observes 'AIO.currentUser.isGithubAuthenticated'

