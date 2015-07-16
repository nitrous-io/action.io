require 'digest/md5'

class UserMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous <support@#{ENV['RAILS_DOMAIN']}>"

  def n2o_bonus_alert(n2o_fill_id)
    @n2o_fill = N2oFill.find(n2o_fill_id)
    @user = @n2o_fill.user

    mail(subject: "Congrats! We allocated #{@n2o_fill.amount} units of N2O to your Nitrous account",
         to: @user.email)
  end

  def private_beta_thanks(user_id)
    @user = User.find(user_id)

    mail(subject: "Nitrous is now open to all! Thank you for participating in our private beta",
         to: @user.email)
  end

  def box_memory_hit_limit_alert(box_id)
    @box = Box.find(box_id)
    @owner = @box.owner

    mail(subject: "You seem to have hit memory limits on your Nitrous box - #{@box.name}",
         to: @owner.email)
  end

  def box_termination_notice(box_id)
    @box = Box.find(box_id)
    @owner = @box.owner
    @days = 5 # TODO Make this configurable.
    @termination_date = @days.days.from_now.to_date.to_s(:long)

    mail(subject: %Q{Nitrous Box Termination Notice: #{@box.name}},
         to: @owner.email)
  end

  # One-time apology email to users who were incorrectly sent a box termination notice.
  # Their boxes were touched_at == nil but created_at > 3.months.ago.
  def box_termination_apology(box_id)
    @box = Box.find(box_id)
    @owner = @box.owner

    mail(subject: %Q{Apologies from Nitrous re: your box #{@box.name}},
         to: @owner.email,
         cc: 'Chu Yeow <chuyeow@nitrous.io>')
  end

  def confirmation_reminder_1(user_id)
    @user = User.find(user_id)

    mail(subject: "Activate Your Nitrous Account",
        to: @user.email,
        from: 'AJ Solimine <ajs@nitrous.io>')
  end

  def confirmation_reminder_2(user_id)
    @user = User.find(user_id)

    mail(subject: "Activate Your Nitrous Account",
        to: @user.email,
        from: 'Greg <support@nitrous.io>')
  end

  def confirmation_reminder_3(user_id)
    @user = User.find(user_id)

    mail(subject: "Your Nitrous Account is waiting",
        to: @user.email,
        from: 'Nitrous <hello@nitrous.io>')
  end

  # to be triggered manually
  def final_reminder(user_id, disc_amount)
    @user = User.find(user_id)
    @disc = disc_amount
    case disc_amount
    when 25
      prefix = 'LQD'
    when 50
      prefix = 'LHD'
    else
      raise "Wrong disc amount"
    end

    sig = Digest::MD5.hexdigest(@user.username)[0..3]
    code = [prefix, @user.username, sig].join('.')

    @coupon_url = "https://pro.nitrous.io/app/#/claim?code=#{code}"

    @boxes = @user.boxes.unterminated.map(&:name)
    return if @boxes.size == 0

    mail(subject: "Final reminder: your Nitrous Lite #{'box'.pluralize(@boxes.size)} will soon become unavailable",
         to: @user.email,
         from: 'Nitrous <support@nitrous.io>')
  end

  def final_reminder_paid(user_id, new_username, reset_token)
    @new_username = new_username
    @user = User.find(user_id)
    sig = Digest::MD5.hexdigest(@user.username)[0..3]
    code = ['LMD', @user.username, sig].join('.')

    @coupon_url = "https://pro.nitrous.io/app/#/claim?code=#{code}"
    @reset_url = "https://pro.nitrous.io/app/#/reset-password?token=#{reset_token}"

    @boxes = @user.boxes.unterminated.map(&:name)
    return if @boxes.size == 0

    mail(subject: "Final reminder: your Nitrous Lite #{'box'.pluralize(@boxes.size)} will soon become unavailable",
         to: @user.email,
         from: 'Nitrous <support@nitrous.io>')
  end
end
