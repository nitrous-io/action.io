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
end
