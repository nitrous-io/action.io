class AddBusinessSurveyToBonuses < ActiveRecord::Migration
  def change
    add_column :bonuses, :business_survey, :datetime
  end
end
