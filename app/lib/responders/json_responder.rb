module Responders::JsonResponder
  protected

  def api_behavior(error)
    if put?
      # render resource instead of 204 no content
      display resource, :status => :ok
    else
      super
    end
  end
end
