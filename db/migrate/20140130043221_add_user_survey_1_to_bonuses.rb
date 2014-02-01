class AddUserSurvey1ToBonuses < ActiveRecord::Migration
  def change
    add_column :bonuses, :user_survey_1, :datetime
  end
end
