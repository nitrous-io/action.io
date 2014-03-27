AIO.TimingMetrics =
  record: (metric, duration, opts = {}) ->
    data = _.extend { duration: duration }, opts

    jQuery.ajax
      url:        "/timing/#{metric}"
      dataType:   'json'
      type:       'POST'
      data:       data
