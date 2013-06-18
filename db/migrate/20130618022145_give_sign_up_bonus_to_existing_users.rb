class GiveSignUpBonusToExistingUsers < ActiveRecord::Migration
  def up
    if KeyValue[N2oFill::N2O_SIGN_UP_BONUS].nil?
      KeyValue.create(key: N2oFill::N2O_SIGN_UP_BONUS, value: 155)
    end
    User.find_each(batch_size: 1000) do |u|
      unless u.n2o_fills.where(kind: N2oFill::Kind::SIGN_UP).any?
        u.send(:give_sign_up_bonus)
      end
    end
  end

  def down
    N2oFill.where(kind: N2oFill::Kind::SIGN_UP).destroy_all
  end
end
