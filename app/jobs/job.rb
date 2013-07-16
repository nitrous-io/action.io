class Job
  def error(job, exception)
    Airbrake.notify(exception) if defined? Airbrake
    super if defined? super
  end
end
