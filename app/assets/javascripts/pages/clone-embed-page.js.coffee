window.App ||= {}

class App.CloneEmbedPage
  constructor: ->
    @$html = $('#code-html')
    @$markdown = $('#code-markdown')
    @$htmlTemplate = Handlebars.compile $('#code-html-template').html()
    @$markdownTemplate = Handlebars.compile $('#code-markdown-template').html()

    $('input[name="button-type"]').change @generateCode.bind(this)
    $('input[name="scm"]').change @generateCode.bind(this)
    $('#repo-url').bind 'input', @generateCode.bind(this)

    @generateCode()
    @textareaSelectText()

  generateCode: ->
    @generateHTML()
    @generateMarkdown()

  generateHTML: ->
    output = @$htmlTemplate(
      image: @buttonImage()
      scm: @scm()
      repoURL: @repoURL()
    )
    @$html.val(output)
    @$html.height(0).height(@$html[0].scrollHeight)

  generateMarkdown: ->
    output = @$markdownTemplate(
      image: @buttonImage()
      scm: @scm()
      repoURL: @repoURL()
    )
    @$markdown.val(output)
    @$markdown.height(0).height(@$markdown[0].scrollHeight)

  buttonImage: ->
    $('input[name="button-type"]:checked').val()

  scm: ->
    $('input[name="scm"]:checked').val()

  repoURL: ->
    encodeURIComponent $('#repo-url').val()

  textareaSelectText: ->
    onFocus = ->
      $this = $(this)
      $this.select()

      # HACK: get it to work on Chrome.
      $this.mouseup ->
        $this.unbind 'mouseup'
        false
    @$html.focus onFocus
    @$markdown.focus onFocus
