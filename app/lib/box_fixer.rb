# FIXME: considering this as an anti-pattern but we want to fix dangling boxes
# asap. Remove this whenever you think we are ready.
class BoxFixer
  def self.fix(box)
    case box.state
    when "starting"
      box.update_attribute :state, "running"
      box.enqueue_restart
    when "stopping"
      box.update_attribute :state, "running"
      box.enqueue_stop
    when "restarting"
      box.update_attribute :state, "running"
      box.enqueue_restart
    when "terminating"
      box.update_attribute :state, "stopped"
      box.enqueue_terminate
    when "reconfiguring"
      box.update_attribute :state, "running"
      box.enqueue_stop
    end
  end
end
