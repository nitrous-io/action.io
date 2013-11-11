AIO.rainbow =
  getAuthToken: (callback) ->
    $.get('/rainbow/auth_token').done (data) =>
      if data.auth_token?
        callback data.auth_token
