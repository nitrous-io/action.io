module EnableN2oHelper
  def set_EnableN2o(val) # unconventional naming for ease of grep when eventually removed
    raise if ![true, false].include?(val)
    setting_const = 'EnableN2o'
    Object.send(:remove_const, setting_const)
    Object.const_set(setting_const, val)
  end
end
