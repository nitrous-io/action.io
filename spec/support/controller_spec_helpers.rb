module ControllerSpecHelpers
  def stub_action(action)
    described_class.class_eval do
      alias_method :"orig_#{action}", action.to_sym
      define_method action.to_sym do
        render nothing: true
      end
    end
  end

  def restore_action(action)
    described_class.class_eval do
      alias_method action.to_sym, :"orig_#{action}"
    end
  end

  # config is obtained by calling ActiveRecord::Base.remove_connection
  # before this method is called.
  # Remember to call ActiveRecord::Base.establish_connection before
  # any database assertions are made in your spec.
  #
  # Stolen from: http://blog.ardes.com/2006/12/12/testing-concurrency-in-rails-using-fork
  def fork_with_new_connection(config, klass = ActiveRecord::Base)
    fork do
      begin
        klass.establish_connection(config)
        yield
      ensure
        klass.remove_connection
      end
    end
  end

  def signed_in?(user)
    # session_info looks like [[user_id_int], "somekey"]
    session_info = response.request.env['rack.session']['warden.user.user.key']
    session_info.present? && session_info[0][0] == user.id
  end
end
