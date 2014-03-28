window.AIO ||= {}

AIO.localStorage =
  set: (key, value) ->
    if Modernizr.localstorage
      if value == null || value == undefined
        window.localStorage.removeItem "aio:#{key}"
      else
        window.localStorage.setItem "aio:#{key}", JSON.stringify(value)

  get: (key) ->
    if Modernizr.localstorage
      if json = window.localStorage.getItem "aio:#{key}"
        JSON.parse json
