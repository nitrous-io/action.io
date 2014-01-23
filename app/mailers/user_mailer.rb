class UserMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

  def n2o_bonus_alert(n2o_fill_id)
    @n2o_fill = N2oFill.find(n2o_fill_id)
    @user = @n2o_fill.user

    mail(subject: "Congrats! We allocated #{@n2o_fill.amount} units of N2O to your Nitrous.IO account",
         to: @user.email)
  end

  def private_beta_thanks(user_id)
    @user = User.find(user_id)

    mail(subject: "Nitrous.IO is now open to all! Thank you for participating in our private beta",
         to: @user.email)
  end

  def box_memory_hit_limit_alert(box_id)
    @box = Box.find(box_id)
    @owner = @box.owner

    mail(subject: "You seem to have hit memory limits on your Nitrous.IO box - #{@box.name}",
         to: @owner.email)
  end

  def box_termination_notice(box_id)
    @box = Box.find(box_id)
    @owner = @box.owner
    @days = 5 # TODO Make this configurable.
    @termination_date = @days.days.from_now.to_date.to_s(:long)

    mail(subject: %Q{Nitrous.IO Box Termination Notice: #{@box.name}},
         to: @owner.email)
  end

  # One-time apology email to users who were incorrectly sent a box termination notice.
  # Their boxes were touched_at == nil but created_at > 3.months.ago.
  def box_termination_apology(box_id)
    @box = Box.find(box_id)
    @owner = @box.owner

    mail(subject: %Q{Apologies from Nitrous.IO re: your box #{@box.name}},
         to: @owner.email,
         cc: 'Chu Yeow <chuyeow@nitrous.io>')
  end

  def confirmation_reminder_1(user_id)
    @user = User.find(user_id)

    mail(subject: "Activate Your Nitrous.IO Account",
        to: @user.email,
        from: 'AJ Solimine <ajs@nitrous.io>')
  end

  def confirmation_reminder_2(user_id)
    @user = User.find(user_id)

    mail(subject: "Activate Your Nitrous.IO Account",
        to: @user.email,
        from: 'Greg <support@nitrous.io>')
  end

  def confirmation_reminder_3(user_id)
    @user = User.find(user_id)

    mail(subject: "Your Nitrous.IO Account is waiting",
        to: @user.email,
        from: 'Nitrous.IO <hello@nitrous.io>')
  end
end
