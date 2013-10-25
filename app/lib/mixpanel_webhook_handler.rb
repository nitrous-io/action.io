class MixpanelWebhookHandler
  def self.handle!(users, event)
    parsed_users = JSON.parse(users)

    parsed_users.each do |user_data|
      email = user_data['$properties']['$email']
      if user = User.find_by_email(email)
        if user.confirmed_at.nil?
          if event == "1day"
            UserMailer.confirmation_reminder_1(user.id).deliver
          elsif event == "7days"
            UserMailer.confirmation_reminder_2(user.id).deliver
          elsif event == "14days"
            UserMailer.confirmation_reminder_3(user.id).deliver
          end
        end
      end
    end
  end
end
