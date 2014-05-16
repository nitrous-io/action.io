class Notifier < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: 'Nitrous.IO Team <hello@nitrous.io>'

  def dangling_boxes_information
    created_at = 10.minutes.ago

    dangling_boxes = Box.dangling.where('created_at < ?', created_at).order('created_at DESC')
    return if dangling_boxes.count == 0

    @paid_boxes, @free_boxes = dangling_boxes.partition { |box| box.premium? }

    headers["X-SMTPAPI"] = JSON.generate(category: 'nitrous-admin')

    mail(subject: "Dangling Boxes on #{ENV['RAILS_HOST']} as of #{created_at.to_s(:long)}",
         to:      "eng@nitrous.io")
  end

  def box_provisioning_failed(box_id)
    @box = Box.find(box_id)

    headers["X-SMTPAPI"] = JSON.generate(category: 'nitrous-admin')

    mail(subject: "Provisioning Failed - Box #{@box.id}",
         to:      ['eng@nitrous.io', 'webapp@nitrous-io.pagerduty.com'])
  end

  def collaboration_invite(route={})
    @from_user = User.find(route[:from])
    @to_user = User.find(route[:to])
    @box = Box.find(route[:box])

    headers["X-SMTPAPI"] = JSON.generate(category: 'collaboration-invite')
    mail(subject: "Invitation to collaborate on #{@box.name} on Nitrous.IO",
         to:      @to_user.email)
  end

  def collaboration_mention(user_id, author, box_name)
    @to_user = User.find(user_id)
    @author = author
    @box_name = box_name

    headers["X-SMTPAPI"] = JSON.generate(category: 'notify-mention-to-collaborator')
    mail(subject: "#{@author} mentioned you in the box \"#{@box_name}\"",
         to:      @to_user.email)
  end

  def stats
    @daily_sign_ups_sma30 = User.where('banned_at IS NULL AND deleted_at IS NULL').where('created_at >= ?', 30.days.ago).count / 30.0
    @num_total_users = User.where('banned_at IS NULL AND deleted_at IS NULL').count
    paid_subscription_states = %w(active delinquent)
    @num_paid_users = User.joins(:subscription).where('subscriptions.state IN (?)', paid_subscription_states).count
    @num_paid_team_plan_users = User.joins('INNER JOIN subscriptions ON subscriptions.user_id = users.id').joins('INNER JOIN plans ON plans.id = subscriptions.plan_id').where('subscriptions.state IN (?)', paid_subscription_states).where('plans.id IN (?)', PlanGroup.find_by_name('teams').plans.select('plans.id').map(&:id)).count
    @plan_mix = User.joins('INNER JOIN subscriptions ON subscriptions.user_id = users.id').joins('INNER JOIN plans ON plans.id = subscriptions.plan_id').where('subscriptions.state IN (?)', paid_subscription_states).group('plans.id').order('plans.id').select('plans.id AS p_id, plans.name AS p_name, COUNT(users.id) AS u_count').map {|o| ["#{o.p_id}-#{o.p_name}", o.u_count]}

    headers["X-SMTPAPI"] = JSON.generate(category: 'nitrous-admin')

    mail(subject: "Stats on #{ENV['RAILS_HOST']} as of #{Time.now.strftime('%e %b %Y %H:%m:%S%p')}",
         to:      "stats@nitrous.io")
  end
end
