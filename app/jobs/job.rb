class Job
  def error(job, exception)
    Airbrake.notify(exception) if defined? Airbrake
  end
end
