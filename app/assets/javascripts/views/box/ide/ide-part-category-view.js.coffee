App.IdePartCategoryView = Em.View.extend
  tagName: 'li'
  templateName: 'templates/box/ide/part-category'
  classNames: [ 'category' ]

  content: null

  name: (->
    @get 'content.name'
  ).property 'content.name'

  description: (->
    {
      'data_stores': 'Popular SQL and NoSQL data stores'
      'deployment': 'Tools for deploying applications to Heroku, Google AppEngine, etc.'
      'development_tools': 'Build and dependency management tools for different languages and frameworks'
      'libraries': 'Libraries like ZeroMQ, SpiderMonkey and libmcrypt'
      'programming_languages': 'More programming languages beyond the default stacks'
      'shells': 'Alternatives for the default shell'
      'utilities': 'Various command-line utilities like Ack, Tmux and S3cmd'
      'web_development': 'Frameworks and libraries to create web applications'
    }[@get 'content.name']
  ).property 'content.name'

  iconClass: (->
    {
      'data_stores': 'fa-database'
      'deployment': 'fa-send'
      'development_tools': 'fa-laptop'
      'libraries': 'fa-list'
      'programming_languages': 'fa-file-code-o'
      'shells': 'fa-terminal'
      'utilities': 'fa-gear'
      'web_development': 'fa-code'
    }[@get 'content.name']
  ).property 'content.name'

  didClick: ->
    @get('parentView').showPartsByCategory @get('name')
